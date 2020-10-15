/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
@isTest
public class roUtilizationViewController_Test {
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
            //insert org config
            ResourceOptimizerConfig__c config = new ResourceOptimizerConfig__c(Resource_Start_Hours__c = 9, Resource_Start_Minutes__c = 0, 
                                                                               Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            insert config;
            //create resource
            List<Resource__c> resourceList = roTestDataFactory.createresourceswithdefaultparent(3);
            // Database.insert(resourceList);
            resource = resourceList[0];
            resource2 = resourceList[1];
            resource3 = resourceList[2];
            //provide resource access to dispatch user by group
            Resource_Optimizer_Security__c security = new Resource_Optimizer_Security__c(Resource_Group__c = resource.Resource_Group__c, 
                                                                                         User__c = dispatchUser.Id, RecordTypeId = resOpSecurityResourceGroupRecTypeId);
            Database.insert(security);
        }        
    }
    
    @isTest static void testUtilizationViewController_AllScenarios(){
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
        }
        
        Id groupId = [select id, Resource_Group__c from resource__c limit 1].Resource_Group__c;
        
        // scenario 1
        string json = roUtilizationViewController.getUtilizationdata(string.valueOf(system.now().day()), string.valueOf(system.now().month()), string.valueOf(system.now().year()), 'day', '15days', string.valueOf(groupId));
        system.assertEquals(true, json!=null);
        // check the date
        string strPad = '0';
        date today = system.today();
        date expectedStartDate = today.addDays(-7);
        string day = string.valueOf(expectedStartDate.day()).leftPad(2,strPad); 
        string month = string.valueOf(expectedStartDate.month()).leftPad(2,strPad);
        system.assertEquals(true, json.contains(month+'/'+day));
        
        // Scenario 2
        string json2 = roUtilizationViewController.getUtilizationdata(string.valueOf(system.now().day()), string.valueOf(system.now().month()), string.valueOf(system.now().year()), 'day', 'month', string.valueOf(groupId));
        system.assertEquals(true, json2!=null);
        expectedStartDate = today.toStartOfMonth();
        day = string.valueOf(expectedStartDate.day()).leftPad(2,strPad); 
        month = string.valueOf(expectedStartDate.month()).leftPad(2,strPad);
        system.assertEquals(true, json2.contains(month+'/'+day));
        
        // Scenario 3
        string json3 = roUtilizationViewController.getUtilizationdata(string.valueOf(system.now().day()), string.valueOf(system.now().month()), string.valueOf(system.now().year()), 'week', 'month', string.valueOf(groupId));
        system.assertEquals(true, json3!=null);
        date startDateOfTheMonth = today.toStartOfMonth();
        Date startDateOfTheWeek = startDateOfTheMonth.toStartOfWeek();
        string checkDate = startDateOfTheWeek.month() +'/'+ string.valueOf(startDateOfTheWeek.day()).leftPad(2,strPad);
        system.assertEquals(true, json3.contains(checkDate));
        
        // Scenario 4
        string json4 = roUtilizationViewController.getUtilizationdata(string.valueOf(system.now().day()), string.valueOf(system.now().month()), string.valueOf(system.now().year()), 'week', 'quarter', string.valueOf(groupId));
        system.assertEquals(true, json4!=null);
       
        startDateOfTheMonth = today.toStartOfMonth();
        startDateOfTheWeek = startDateOfTheMonth.toStartOfWeek();
        checkDate = startDateOfTheWeek.month() +'/'+ string.valueOf(startDateOfTheWeek.day()).leftPad(2,strPad);
        system.assertEquals(true, json4.contains(checkDate));
        
        // Scenario 5
        string json5 = roUtilizationViewController.getUtilizationdata(string.valueOf(system.now().day()), string.valueOf(system.now().month()), string.valueOf(system.now().year()), 'month', 'quarter', string.valueOf(groupId));
        system.assertEquals(true, json5!=null);
        expectedStartDate = system.today();
        month = string.valueOf(expectedStartDate.month()).leftPad(2,strPad);
        system.assertEquals(true, json5.contains(month));
        
        // Scenario 6
        string json6 = roUtilizationViewController.getUtilizationdata(string.valueOf(system.now().day()), string.valueOf(system.now().month()), string.valueOf(system.now().year()), 'month', 'Year', string.valueOf(groupId));
        system.assertEquals(true, json6!=null);
        expectedStartDate = system.today();
        month = string.valueOf(expectedStartDate.month()).leftPad(2,strPad);
        system.assertEquals(true, json6.contains(month));
        Test.stopTest();
    }
}