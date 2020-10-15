/************************************************************************ 
Author : Santosh
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
@isTest
public class roRGHierarchyController_Test extends roTestDataFactory{
    
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

        
     }
    
    testMethod static void testgrouphierarchy(){
       test.startTest();
        setup();
         system.runAs(adminUser){
            //insert org config
            ResourceOptimizerConfig__c config = new ResourceOptimizerConfig__c(Resource_Start_Hours__c = 9, Resource_Start_Minutes__c = 0, 
                Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            insert config;
            //create resource
             List<Resource_group__c> RGS = createresourcegroups(5);
            insert RGS;
            for(integer i = 1;i<5;i++){
               RGS[i].Parent_Group__c =  RGS[0].id;
            }
            RGS[0].name = 'Master';
            update RGS;
            List<Resource__c> resourceList = createresourceswithcustomparent(5,RGS[0].id);
            //provide resource access to dispatch user by group
            Resource_Optimizer_Security__c security = createresourcegroupsecurity(dispatchUser.id,RGS[0].id);
        }
        
        system.runAs(dispatchUser){
          Resource_group__c RG = [select id,name from Resource_group__c where name = 'Master' LIMIT 1];  
            if(RG != null){
               String RES = roResourceGroupHierarchyController.gethierarchy(RG.id);
            }
        }
        test.stopTest();
    }

}