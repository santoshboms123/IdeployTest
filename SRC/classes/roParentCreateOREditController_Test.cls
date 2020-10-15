/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
@isTest
public class roParentCreateOREditController_Test {
    @testSetup static void setup(){
        // create test users
        List<User>lstUsers = roTestDataFactory.createUsers(100);
        insert lstUsers;
        
        // Create admin user
        List<User> adminUsers = roTestDataFactory.createUsers(1, 'AdminUser');
        insert adminUsers;
        
        //Assign Permissionset to Admin User
        roTestDataFactory.assignPermissionSetToUsers(roTestDataFactory.permissionSetType.roAdmin, new List<Id>{adminUsers[0].Id});
    }
    
    @isTest static void testgetAllObjects() {
        user adminUser = [select id, name from user where lastname='AdminUser0' limit 1];
        system.runAs(adminUser){
            List<string> SObjectList = roParentCreateOREditController.getAllObjects();
            System.assertEquals(true,SObjectList.size()>0);
        }
    }
    
    @isTest static void testSelectedParentObjectFields() {
        user adminUser = [select id, name from user where lastname='AdminUser0' limit 1];
        system.runAs(adminUser){
            string selectedObject = 'Account';
            List<string> fieldsList = roParentCreateOREditController.objectFields(selectedObject);
            System.assertEquals(true,fieldsList.size()>0);
            
            List<string> dateTimefieldsList = roParentCreateOREditController.objectDatetimeFields(selectedObject);
            System.assertEquals(true,dateTimefieldsList.size()>0);
            
            List<string> textfieldsList = roParentCreateOREditController.objectTextFields(selectedObject);
            System.assertEquals(true,textfieldsList.size()>0);
            
            List<string> recordTypeList = roParentCreateOREditController.objectRecordTypes(selectedObject);
            System.assertEquals(true,recordTypeList.contains('Master'));
        }  
    }
    
    @isTest static void testValidateSoql() {
        user adminUser = [select id, name from user where lastname='AdminUser0' limit 1];
        system.runAs(adminUser){
            // Positive scenario
            String soql = 'Select Id, name from Account Limit 1';
            boolean resultFlag = roParentCreateOREditController.validatesoql(soql);
            System.assertEquals(true,resultFlag);
            
            // negative scenario
            soql = '';
            resultFlag = roParentCreateOREditController.validatesoql(soql);  
            System.assertEquals(false,resultFlag);
        }
    }
    
    @isTest static void testgetCurrentData() {
        user adminUser = [select id, name from user where lastname='AdminUser0' limit 1];
        system.runAs(adminUser){
            List<string> selectedFields = new List<string>{'Name'};
                string soql = 'select id from Account';
            
            string rapId = roParentCreateOREditController.saveRAParent(null, 'Account', soql, null, selectedFields, 'CreatedDate', 'LastModifiedDate', 'Name', 'Master');
            System.assertEquals(true,rapId!=null);
            
            roCalendarWrapper.resourceAllocationParentWrapper rapWrapper = roParentCreateOREditController.getCurrentData(rapId);
            System.assertEquals(true,rapWrapper!=null);
        }
    }
    
    
    @isTest static void testgetCurrentData2() {
        user adminUser = [select id, name from user where lastname='AdminUser0' limit 1];
        system.runAs(adminUser){
            List<string> selectedFields = new List<string>{'Name'};
                string soql = 'select id from Account';
            
            try{
                string rapId = roParentCreateOREditController.saveRAParent(null, null, soql, null, selectedFields, 'CreatedDate', 'LastModifiedDate', 'Name', 'Master');
            }
            catch(exception e){
                system.assertEquals(e.getMessage(),'Script-thrown exception');
            }
        }
    }
    
    @isTest static void testgetCurrentData3() {
        user adminUser = [select id, name from user where lastname='AdminUser0' limit 1];
        system.runAs(adminUser){
            try{
                Id rapId = null;
                roCalendarWrapper.resourceAllocationParentWrapper rapWrapper = roParentCreateOREditController.getCurrentData(rapId);
                system.assertEquals(null, rapWrapper);
            }
            catch(exception e){
                system.assertEquals(true, e.getMessage().contains('Invalid id'));
            }
        }
    }
}