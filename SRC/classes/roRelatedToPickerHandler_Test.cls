/************************************************************************ 
Author : Santosh 
Details: 
    Purpose : roRelatedToPickerHandler_Test - Test class to cover roRelatedToPickerHandler Scenarios
    Intial release date : October 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
@isTest
public with sharing class roRelatedToPickerHandler_Test {
    @testSetup static void setup() {

       List<Account> TestAccounts = New List<Account>();
        For(integer i =0; i<5 ; i++){
            Account A = New Account(name = 'TestAccount'+String.valueOf(i));
            TestAccounts.add(A);
        }
        insert TestAccounts;
    }
    
    testMethod static void fetchresults(){
        Test.startTest();
       List<Resource_Optimizer_Relatedto_Config__mdt> ROR =  roRelatedToPickerHandler.getobjects();
       List<roRelatedToPickerHandler.returnresponse> RES = roRelatedToPickerHandler.getresults('Test', 'Account');
        System.debug('Result'+RES.size());
        System.assertEquals(5, RES.size());
        
        Test.stopTest();
        
    }
}