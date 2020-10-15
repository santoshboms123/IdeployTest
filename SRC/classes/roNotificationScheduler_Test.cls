/************************************************************************ 
Author : Sukku
Details: 
    Purpose : roNotificationScheduler_Test - Test Class to Cover roNotificationScheduler
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
@isTest
public with sharing class roNotificationScheduler_Test extends ROTestDataFactory{
     public static Resource__c resource {get; set;}
	public static User dispatchUser {get; set;}
    public static User adminUser {get; set;}
    public static User resourceUser {get; set;}
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
         resourceUser = userList[2];
        assignPermissionSetToUsers(permissionSetType.roResource, new List<Id>{adminUser.Id});

        system.runAs(adminUser){
            //insert org config
            ResourceOptimizerConfig__c config = new ResourceOptimizerConfig__c(Resource_Start_Hours__c = 9, Resource_Start_Minutes__c = 0, 
                Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0, Allocation_alert_interval__c = 30);
            insert config;
            //create resource
            List<Resource_Group__c> testgroup = createresourcegroups(1);
            insert testgroup; 
           	List<Resource__c> testresources = createresourceswithcustomparent(5,testgroup[0].id);
            resource = testresources[0];
            testresources[0].user__c = resourceUser.id ;
            testresources[0].Recieve_Allocation_Alerts__c = true;
            update testresources[0] ;
            //provide resource access to dispatch user by group
            Resource_Optimizer_Security__c security = new Resource_Optimizer_Security__c(Resource_Group__c = testgroup[0].id, 
            User__c = dispatchUser.Id, RecordTypeId = resOpSecurityResourceGroupRecTypeId);
            Database.insert(security);
           
            List<Resource_Allocation__c> RAS = new List<Resource_Allocation__c>();
            
            datetime teststartdatetime = system.now(); 
            datetime testEnddatetime = system.now().addMinutes(30); 
            datetime teststartdatetime2 = system.now().addMinutes(35); 
            datetime testEnddatetime2 = system.now().addMinutes(55); 
            
            for(integer i =0; i<5 ; i++){
               Resource_Allocation__c RA1 = new Resource_Allocation__c(Allocated_Start_DateTime__c = teststartdatetime, Allocated_End_Datetime__c = testEnddatetime , Resource__c = testresources[i].id ); 
               Resource_Allocation__c RA2 = new Resource_Allocation__c(Allocated_Start_DateTime__c = teststartdatetime2, Allocated_End_Datetime__c = testEnddatetime2 , Resource__c = testresources[i].id ); 
           	RAS.add(RA1);
            RAS.add(RA2);    
            }
            insert RAS ; 
            
        } 
     }
    
    testMethod static void ronotificationTest(){
        Test.startTest();
        setup();
		roNotificationScheduler sh1 = new roNotificationScheduler();

		String sch = '0 0 23 * * ?'; 
        system.schedule('Test Check', sch, sh1); 
        Test.stopTest(); 
    
    }
}