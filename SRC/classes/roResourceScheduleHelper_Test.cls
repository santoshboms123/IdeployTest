/************************************************************************ 
Author : Sukku
Details: 
Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
a wrapper response to mobilecalendar Web component. 
Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
@isTest
public class roResourceScheduleHelper_Test {
    public static Resource__c resource {get; set;}
    public static Resource__c resource2 {get; set;}
    public static Resource__c resource3 {get; set;}
    public static User dispatchUser {get; set;}
    public static User adminUser {get; set;}
    
    static void setup(){
        Id resOpSecurityResourceGroupRecTypeId = Schema.SObjectType.Resource_Optimizer_Security__c.getRecordTypeInfosByName().get('Resource Group').getRecordTypeId();
        //create dispatch user
        List<User> userList = roTestDataFactory.createUsers(2);
        Database.insert(userList);
        //assign permission set to user
        dispatchUser = userList[0];
        roTestDataFactory.assignPermissionSetToUsers(roTestDataFactory.permissionSetType.roDispatcher, new List<Id>{dispatchUser.Id});
        adminUser = userList[1];
        roTestDataFactory.assignPermissionSetToUsers(roTestDataFactory.permissionSetType.roAdmin, new List<Id>{adminUser.Id});
        
        system.runAs(adminUser){
            List<Resource_group__c> rGroups = roTestDataFactory.createresourcegroupswithdefaultparent(1);
            ResourceOptimizerConfig__c config = new ResourceOptimizerConfig__c(Resource_Start_Hours__c = 9, Resource_Start_Minutes__c = 0, 
                                                                               Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            insert config;
            // Create Resources
            List<Resource__c> resourceList = roTestDataFactory.createresourceswithdefaultparent(3);
            resource = resourceList[0];
            resource.Resource_Default_Start_Time__c = Time.newInstance(8, 0, 0, 0);
            resource.Resource_Default_End_Time__c = Time.newInstance(17, 0, 0, 0);
            update resource;
            resource2 = resourceList[1];
            resource3 = resourceList[2];
            
            //provide resource access to dispatch user by group
            Resource_Optimizer_Security__c security = new Resource_Optimizer_Security__c(Resource_Group__c = resource.Resource_Group__c, 
                                                                                         User__c = dispatchUser.Id, RecordTypeId = resOpSecurityResourceGroupRecTypeId);
            Database.insert(security);
        }        
    }
    
    @isTest static void testScheduleHelper(){
        Test.startTest();
        setup();
        system.runAs(dispatchUser){
            //create new allocation for the resource as dispatcher
            Resource_Allocation__c resAlloc = new Resource_Allocation__c(
                Allocated_Start_DateTime__c = System.now(), 
                Allocated_End_Datetime__c = System.now().addhours(13), 
                Calculate_Utilization__c = true, 
                Resource__c = resource.Id);
            Database.insert(resAlloc);
            
            //query utilization records created 
            Map<Id, Resource_Utilization__c> dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>(
                [SELECT Id, Booked_Time_Slots__c, Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c, Utilization_Date__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                 AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            
            List<Resource_Utilization__c> weekEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id AND RecordTypeId = :roTestDataFactory.WEEKLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> monthEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id AND RecordTypeId = :roTestDataFactory.MONTHLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> quarterEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id AND RecordTypeId = :roTestDataFactory.QUARTERLYUTILIZATIONRECTYPEID];
            List<Resource_Available_Hours__c> resourceAvailableHours = [SELECT Id FROM Resource_Available_Hours__c WHERE Resource_Utilization__c  IN :dateEfficiencyRecType.keyset()];
            
            
            Id groupId = [select id, Resource_Group__c from resource__c limit 1].Resource_Group__c;
            string stDate = string.valueOf(system.today().addDays(-1));
            string eDate = string.valueOf(system.today().addDays(1));
            roCalendarWrapper.ResourceScheduleWrapper rsw = roResourceScheduleHelper.getResourceAllocationJSON(stDate, eDate, string.valueOf(groupId));
            system.assertEquals(True, rsw!=null);
            // logic to check other asserts   
            roCalendarWrapper.ResourceSchedule rs = rsw.ResourceSchedule;
            List<roCalendarWrapper.ResourceGroup> rg = rs.ResourceGroup;
            List<roCalendarWrapper.Resource> lstR = rg[0].Resource;
            List<String> lstResIds = new List<String>();
            roCalendarWrapper.Resource re = new roCalendarWrapper.Resource();
            for(roCalendarWrapper.Resource r: lstR){ lstResIds.add(r.ResourceID); re = string.valueOf(resource.Id) == r.ResourceID ? r : null;}
            roCalendarWrapper.AssignedRecords ar = re.AssignedRecords;
            List<roCalendarWrapper.Day> day = ar.Day;
            List<roCalendarWrapper.Record> lstRecords = day[0].Record;  
            // asserts
            system.assertEquals(true, lstResIds.contains(string.valueOf(resource.Id)));
            system.assertEquals([select id, name from Resource_Allocation__c limit 1].Name, lstRecords[0].Recordname);
            
            
            // Group is blank
            string gid = '';
            roCalendarWrapper.ResourceScheduleWrapper rsw1 = roResourceScheduleHelper.getResourceAllocationJSON(stDate, eDate, gid);
            system.assertEquals(True, rsw1==null);
            
            // error scenario
            try{
                roCalendarWrapper.ResourceScheduleWrapper rsw_error = roResourceScheduleHelper.getResourceAllocationJSON(stDate, null, string.valueOf(groupId));
            }
            catch(exception e){
                system.assertEquals(true, e.getMessage().contains('Argument cannot be null'));
            }
            
        }
    }
}