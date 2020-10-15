/************************************************************************ 
Author : Santosh Rao Bompally 
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
@isTest
public with sharing class roAppointmentBookerController_Test extends ROTestDataFactory{
     public static string skillId {get; set;}
    public static string ReservationId {get; set;}
    public static User dispatchUser {get; set;}
    public static User adminUser {get; set;}
    public static List<Id> ResourceIds {get; set;}
     static void setup(){
            Id resOpSecurityResourceGroupRecTypeId = Schema.SObjectType.Resource_Optimizer_Security__c.getRecordTypeInfosByName().get('Resource Group').getRecordTypeId();
        //create dispatch user
        List<User> userList = createUsers(3);
        Database.insert(userList);
        //assign permission set to user
        dispatchUser = userList[0];
        assignPermissionSetToUsers(permissionSetType.roDispatcher, new List<Id>{dispatchUser.Id});
        adminUser = userList[1];
        assignPermissionSetToUsers(permissionSetType.roAdmin, new List<Id>{adminUser.Id});
        

        system.runAs(adminUser){
            //insert org config
            ResourceOptimizerConfig__c config = new ResourceOptimizerConfig__c(Resource_Start_Hours__c = 9, Resource_Start_Minutes__c = 0, 
                Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            insert config;
            //create resource
            List<Resource_Group__c> testgroup = createresourcegroups(1);
            insert testgroup; 
           	List<Resource__c> testresources = createresourceswithcustomparent(2,testgroup[0].id);
            //provide resource access to dispatch user by group
            Resource_Optimizer_Security__c security = createresourcegroupsecurity(dispatchUser.Id,testgroup[0].id); 
            
           List<Resource_Allocation__c> RAS = new List<Resource_Allocation__c>();
            
            datetime teststartdatetime = system.now(); 
            datetime testEnddatetime = system.now().addMinutes(30); 
            datetime teststartdatetime2 = system.now().addMinutes(35); 
            datetime testEnddatetime2 = system.now().addMinutes(55); 
            
            for(integer i =0; i<2 ; i++){
               
               Resource_Allocation__c RA1 = new Resource_Allocation__c(Allocated_Start_DateTime__c = teststartdatetime, Allocated_End_Datetime__c = testEnddatetime , Resource__c = testresources[i].id,Calculate_Utilization__c = true ); 
             //  Resource_Allocation__c RA2 = new Resource_Allocation__c(Allocated_Start_DateTime__c = teststartdatetime2, Allocated_End_Datetime__c = testEnddatetime2 , Resource__c = testresources[i].id,Calculate_Utilization__c = true  ); 
           	RAS.add(RA1);
          //  RAS.add(RA2);    
            }
            insert RAS ; 
            //system.debug('allocations'+[select id,name from resource__c]);
           
            
        } 
     }
     testmethod Static void test_RScontroller(){
     Test.startTest();
         setup(); 
         system.runAs(dispatchUser){
             List<Id> Rids = new List<Id>();
             for(resource__c R : [select id,name from resource__c]){
                 Rids.add(R.id);
             }
             system.debug('rids'+Rids);
              system.debug('SantoshBookedslots'+[SELECT Id, Resource__c, Booked_Time_Slots__c,Utilization_Date__c,Available_Hours__c,Available_Hours_slots__c  FROM Resource_Utilization__c ]);
            List<roAppointmentBookerController.resourceAvailableJson> RE = roAppointmentBookerController.getAvailableSlotsD(Rids, String.valueOf(system.today()), 'Australia/Sydney');
             
         }
      Test.stopTest();   
     }
}