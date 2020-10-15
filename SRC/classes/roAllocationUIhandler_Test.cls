/************************************************************************ 
Author : Santosh Rao Bompally 
Details: 
    Purpose : roAllocationUIhandler_Test is the Test Class to cover the scenarios handled in roAllocationUIhandler Class
    Intial release date : October 05, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
@isTest
public with sharing class roAllocationUIhandler_Test  extends ROTestDataFactory{
    
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
                Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            insert config;
            //create resource
            List<Resource__c> resourceList = createresourceswithdefaultparent(3);
          // Database.insert(resourceList);
            resource = resourceList[0];
            resource.User__c = resourceUser.id;
            update resource ;
            //provide resource access to dispatch user by group
            Resource_Optimizer_Security__c security = new Resource_Optimizer_Security__c(Resource_Group__c = resource.Resource_Group__c, 
            User__c = dispatchUser.Id, RecordTypeId = resOpSecurityResourceGroupRecTypeId);
            Database.insert(security);
        } 
     }
    
    @isTest static void createallocation() {
        
        setup();
     
	  Test.startTest();
       
        system.runAs(dispatchUser){
        
       String AllocationInput1 = '{"resourceids":"'+resource.id+'","parentid":"a0b1s000001EP9lAAG","isbacklog":false,"startdatetime":"2020-09-22T01:15:00.000Z","enddatetime":"2020-09-22T01:45:00.000Z","subject":"Sample","description":"Test Descriptio","relatedtoid":"0011s00000MisGVAAZ","relatedtoname":"Samskriti","relatedtoobject":"Account","address":{"street":"109 George Street","city":"Parramatta","province":"NSW","postalcode":"2150","country":"Australia"}}';
		String AllocationInput11 = '{"resourceids":"","parentid":"a0b1s000001EP9lAAG","isbacklog":false,"startdatetime":"2020-09-22T01:15:00.000Z","enddatetime":"2020-09-22T01:45:00.000Z","subject":"Sample","description":"Test Descriptio","relatedtoid":"0011s00000MisGVAAZ","relatedtoname":"Samskriti","relatedtoobject":"Account","address":{"street":"109 George Street","city":"Parramatta","province":"NSW","postalcode":"2150","country":"Australia"}}';
  	    String AllocationInput2 = '{"resourceids":"","parentid":"a0b1s000001EP9lAAG","isbacklog":true,"startdatetime":"2020-09-22T01:15:00.000Z","enddatetime":"2020-09-22T01:45:00.000Z","subject":"Sample","description":"Test Descriptio","relatedtoid":"0011s00000MisGVAAZ","relatedtoname":"Samskriti","relatedtoobject":"Account","address":{"street":"109 George Street","city":"Parramatta","province":"NSW","postalcode":"2150","country":"Australia"}}';      
    
       
              // Generic Scenario of Creating Allocation from Dispatch   
      roAllocationUIhandler.allocationresponse RA1 =  roAllocationUIhandler.createallocation(AllocationInput1);
        system.debug('Response'+RA1.Success);
        system.assertEquals(true,RA1.Success);
        // Error Scenario of Creating allocation without resources  
      roAllocationUIhandler.allocationresponse RA11 =  roAllocationUIhandler.createallocation(AllocationInput11);
        system.debug('Response'+RA11.Success);
        system.assertEquals(false,RA11.Success);
        //  Generic Scenario of Creating Backlog Allocation 
         roAllocationUIhandler.allocationresponse RA2 =  roAllocationUIhandler.createallocation(AllocationInput2);
        system.debug('Response'+RA2.Success);
        system.assertEquals(true,RA2.Success);
        //  Scenario of Updating Backloged Allocation with Resource 
         String AllocationInput3 = '{"resourceids":"'+resource.id+'","parentid":"'+RA2.allocationid+'","isbacklog":false,"startdatetime":"2020-09-22T02:15:00.000Z","enddatetime":"2020-09-22T02:45:00.000Z","subject":"Sample","description":"Test Descriptio","relatedtoid":"0011s00000MisGVAAZ","relatedtoname":"Samskriti","relatedtoobject":"Account","address":{"street":"109 George Street","city":"Parramatta","province":"NSW","postalcode":"2150","country":"Australia"}}';
	   	roAllocationUIhandler.allocationresponse RA3 =  roAllocationUIhandler.createallocation(AllocationInput3);
        system.debug('Response'+RA3.Success);
         system.assertEquals(true,RA3.Success);
  	 // check for exceptions    
            List<Resource_Optimizer_Log__c> resourceExceptionLogs = [SELECT Id, Error_Message__c, Event__c, Stack_Trace__c, Exception_caught_by__c FROM Resource_Optimizer_Log__c];
            for(Resource_Optimizer_Log__c logs :resourceExceptionLogs){
                system.debug('EXCEPTION LOGS: '+logs);
            }
            system.assertEquals(0, resourceExceptionLogs.size(), 'Exception records not created.');
            
         
        }
       
        
      
       Test.stopTest(); 
    }
}