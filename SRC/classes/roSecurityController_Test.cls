/*****************************************************************************************
 * Author : 				Santosh Rao Bompally 
 * Class Name : 			roSecurityController_Test
 * Initial Authored Date : 	09 June 2020 
 * Purpose of Code : 		This Class handles all the DML operational Logicto be reffered on Resource_Optimizer_Security__c trigger. 
 * 
 ******************************************************************************************/
@isTest
public class roSecurityController_Test extends roTestDataFactory{
    
     public static Resource__c resource {get; set;}
    public static User dispatchUser {get; set;}
    public static User adminUser {get; set;}
    public static User resourceUser {get; set;}
     static void setup(){
           
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
            
            //create resource
            List<Resource__c> resourceList = createresourceswithdefaultparent(3);
          // Database.insert(resourceList);
            resource = resourceList[0];
            resource.User__c = resourceUser.id;
            update resource ;
            
        } 
     }
    
    testMethod static void roSecurityTest(){
        Test.startTest();
        setup();
        System.runAs(adminUser){
             Id resOpSecurityResourceGroupRecTypeId = Schema.SObjectType.Resource_Optimizer_Security__c.getRecordTypeInfosByName().get('Resource Group').getRecordTypeId();
            ResourceOptimizerConfig__c config = new ResourceOptimizerConfig__c(Resource_Start_Hours__c = 9, Resource_Start_Minutes__c = 0, 
                Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            insert config;
            List<Resource_group__c> RGS = createresourcegroups(5);
            insert RGS;
            for(integer i = 1;i<5;i++){
               RGS[i].Parent_Group__c =  RGS[0].id;
            }
            update RGS;
            List<Resource__c> resourceList = createresourceswithcustomparent(5,RGS[0].id);
            
            //provide resource access to dispatch user by group
            Resource_Optimizer_Security__c security = new Resource_Optimizer_Security__c(Resource_Group__c = RGS[0].id, 
            User__c = dispatchUser.Id, RecordTypeId = resOpSecurityResourceGroupRecTypeId,Access_Level__c='Read');
            Database.insert(security);
            security.Access_Level__c = 'Edit';
            Database.update(security);
            Delete security ;
            
        }
        
        Test.stopTest();
    }

}