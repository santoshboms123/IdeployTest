/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
@isTest
public class roCalendarController_Test {
    @testSetup static void setup(){
        // Create admin user
        List<User> adminUsers = roTestDataFactory.createUsers(1, 'AdminUser');
        insert adminUsers;
        
        //Assign Permissionset to Admin User
        roTestDataFactory.assignPermissionSetToUsers(roTestDataFactory.permissionSetType.roAdmin, new List<Id>{adminUsers[0].Id});
        
        system.runAs(adminUsers[0]){
            // create parent object data (here Resource data..)
            List<Resource__c> lstResources = roTestDataFactory.createresourceswithdefaultparent(5);
            
            // Create resource allocation parent records
            // Parent object 1
            List<string> selectedFields = new List<string>{'Name','First_Name__c','Last_Name__c'};
                string soql = 'select id, Name, First_Name__c, Last_Name__c, CreatedDate, LastModifiedDate from Resource__c';
            string rapId = roParentCreateOREditController.saveRAParent(null, 'Resource__c', soql, null, selectedFields, 'CreatedDate', 'LastModifiedDate', 'Name', 'Master');
            
            // Parent object 2
            List<string> selectedFieldsRU = new List<string>{'Name','Utilization_Date__c','Resource__c'};
                string soqlString = 'select id, Name, Utilization_Date__c, Resource__c, CreatedDate, LastModifiedDate from Resource_Utilization__c';
            string rId_RT1 = roParentCreateOREditController.saveRAParent(null, 'Resource_Utilization__c', soqlString, null, selectedFieldsRU, 'CreatedDate', 'LastModifiedDate', 'Name', 'Daily_Utilization');
            string rId_RT2 = roParentCreateOREditController.saveRAParent(null, 'Resource_Utilization__c', soqlString, null, selectedFieldsRU, 'CreatedDate', 'LastModifiedDate', 'Name', 'Monthly_Utilization');
        }
    }
    
    @isTest static void testgetConnectObjectData() {
        user adminUser = [select id, name from user where lastname='AdminUser0' limit 1];
        system.runAs(adminUser){
            Test.startTest();
            roCalendarWrapper roCW = roCalendarController.getConnectObjectDataNew();
            Test.stopTest();
            system.assertEquals(2, roCW.connectorObjectList.size());
        }
    }
    
    @isTest static void testgetConnectObjectDataException() {
        user adminUser = [select id, name from user where lastname='AdminUser0' limit 1];
        system.runAs(adminUser){
            // update Parent Json to get an exception
            Resource_Allocation_Parent__c raParent = [SELECT Id, Parent_API_Name__c, Parent_JSON__c FROM Resource_Allocation_Parent__c where Parent_API_Name__c = 'Resource__c'];
            string parentJSON = raParent.Parent_JSON__c.replace('Name', 'Namee');
            raParent.Parent_JSON__c = parentJSON;
            update raParent;
            
            // call the method to throw expected exception
            Test.startTest();
            try{
                roCalendarWrapper roCW = roCalendarController.getConnectObjectDataNew();
            }
            catch(exception e){
                system.assertEquals(true, e.getMessage().contains('No such column \'Namee\' on entity'));
            }
            Test.stopTest();
        }
    }
    
    @isTest static void testgetcreateWrapperforCalendarException() {
        user adminUser = [select id, name from user where lastname='AdminUser0' limit 1];
        system.runAs(adminUser){
            Test.startTest();
            try{
                roCalendarWrapper.connectorObject roCObj = roCalendarController.createWrapperforCalendarNew(null, null, null);
            }
            catch(exception e){
                system.assertEquals(true, e.getMessage().contains('Attempt to de-reference a null object'));
            }
            Test.stopTest();
        }
    }
}