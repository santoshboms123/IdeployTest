/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
@isTest
public class roResourceOptimizerSetupController_Test {
    
    static final String jsonStringWithOutId = '{'+ 
        '   \"Name\": \"Resource Optimizer Config (Organization)\",'+
        '	\"Are_your_Users_are_Resources__c\": true,'+
        '	\"Do_you_allow_Overlay__c\":true,' +
        '	\"Do_you_allow_skill_based_assignment__c\":true,' +
        '   \"Organization_Weekends__c\": \"Sunday,Saturday\",'+
        '   \"Allocation_alert_interval__c\":30,'+
        '   \"Resource_Start_Hours__c\":9,'+
        '   \"Break_Time_For_Each_Resource_In_Minutes__c\":45,'+
        '   \"Do_Not_Show_Welcome_Page__c\":true,'+
        '   \"Resource_Start_Minutes__c\":0,'+
        '   \"Resource_End_Hours__c\":17,'+
        '   \"Resource_End_Minutes__c\":0,'+
        '   \"Business_Start_Hours__c\":8,'+
        '   \"Business_Start_Minutes__c\":0,'+
        '   \"Business_End_Hours__c\":17,'+
        '   \"Business_End_Minutes__c\":0,'+
        '   \"Create_Efficiencies_For_Next_N_Days__c\":10,'+
        '   \"resourceStartTime\":\"09:00:00.000Z\",'+
        '   \"resourceEndTime\":\"17:00:00.000Z\",'+
        '   \"organisationBusinessHoursStartTime\":\"08:00:00.000Z\",'+
        '   \"organisationBusinessHoursEndTime\":\"17:00:00.000Z\",'+
        '   \"CreatedDate\":\"2020-06-08T20:58:19.000Z\"'+
        '}';
    
    
    @testSetup static void setup(){
        // create test users
        List<User>lstUsers = roTestDataFactory.createUsers(100);
        insert lstUsers;
        
        // Create admin user
        List<User> adminUsers = roTestDataFactory.createUsers(1, 'AdminUser');
        insert adminUsers;
        
        //Assign Permissionset to Admin User
        roTestDataFactory.assignPermissionSetToUsers(roTestDataFactory.permissionSetType.roAdmin, new List<Id>{adminUsers[0].Id});
        
        system.runAs(adminUsers[0]){
            // create test Resource group
            List<Resource_group__c> lstResourceGroup = roTestDataFactory.createresourcegroups(1);
            insert lstResourceGroup;
            
            // create test Resources
            List<Resource__c> lstAllResource = new List<Resource__c>();
            for(integer i = 0; i <= 2; i++){
                List<Resource__c> lstResource = roTestDataFactory.createresourceswithcustomparent(1, lstResourceGroup[0].id );
                lstResource[0].User__c = lstUsers[i].id;
                lstAllResource.addAll(lstResource);    
            }
            update lstAllResource;
        }
    }
    
    @isTest static void testSetupConfig() {
        user adminUser = [select id, name from user where lastname='AdminUser0' limit 1];
        system.runAs(adminUser){
            List<profile> listProfiles = roResourceOptimizerSetupController.getProfiles();
            System.assertEquals(true,listProfiles.size()>0);
            
            ResourceOptimizerConfig__c config = roResourceOptimizerSetupController.getROSetupConfig();
            System.assertEquals(true,config!=null);
        }
    }
    
    @isTest static void testCreateResources() {
        user adminUser = [select id, name from user where lastname='AdminUser0' limit 1];
        system.runAs(adminUser){
            List<String> lstProfileIds = new List<String>();
            for(profile p: [Select Id, Name from Profile where Name='Standard User']){
                lstProfileIds.add(p.Id); 
            }
            
            try{
                Integer numberOfResourceCreated = roResourceOptimizerSetupController.createResources(lstProfileIds);
                System.assertEquals(98,numberOfResourceCreated);
            }
            catch(exception e){
                system.debug('message ==>'+e.getMessage());
            }
        }
    }
    
    @isTest static void testCreateResources_ErrorCondition() {
        user adminUser = [select id, name from user where lastname='AdminUser0' limit 1];
        system.runAs(adminUser){
            List<String> lstProfileIds = new List<String>();
            try{
                Integer numberOfResourceCreated = roResourceOptimizerSetupController.createResources(lstProfileIds);
            }
            catch(exception e){
                system.debug('message ==>'+e.getMessage());
            }
        }
    }
    
    @isTest static void testupsertROConfig() {
        user adminUser = [select id, name from user where lastname='AdminUser0' limit 1];
        system.runAs(adminUser){
            string configId = roResourceOptimizerSetupController.upsertROConfig(jsonStringWithOutId);
            System.assertEquals(true,configId!=null);
            
            string jsonStringWithId =  jsonStringWithOutId.replace('{', '{ \"Id\": \"'+configId+'\",') ;
            string configIdUpsert = roResourceOptimizerSetupController.upsertROConfig(jsonStringWithId);
            System.assertEquals(true,configIdUpsert!=null);
        }
    }
    
    @isTest static void testcreateResourceDefaultGroup() {
        user adminUser = [select id, name from user where lastname='AdminUser0' limit 1];
        system.runAs(adminUser){
            Resource_Group__c rg = roResourceOptimizerSetupController.createResourceDefaultGroup('abcdefghijklmnopqrstuvwxyz-abcdefghijklmnopqrstuvwxyz-abcdefghijklmnopqrstuvwxyzzzzz');
            System.assertEquals(true,rg==null);
        }
    }
}