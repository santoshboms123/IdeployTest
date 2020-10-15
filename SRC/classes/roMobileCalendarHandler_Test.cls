/************************************************************************ 
Author : Santosh Rao Bompally 
Details: 
    Purpose : MobileCalendarHandler_Test is the apex test class to cover MobileCalendarHandler
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
@isTest
public without sharing class roMobileCalendarHandler_Test extends roTestDataFactory {
    
    public static Resource__c resource {get; set;}
    public static User dispatchUser {get; set;}
    public static User adminUser {get; set;}
    public static User resourceUser {get; set;}
    public static String ReservationReasonID {get; set;}
    
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
        assignPermissionSetToUsers(permissionSetType.roResource, new List<Id>{resourceUser.Id});

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
             Reservation_Reason__c RR = new Reservation_Reason__c(name='Test',Active__c = true,Calculate_Utilization__c = true);
       		 insert RR; 
        	ReservationReasonID = RR.id;
                   
        
            
              
        } 
    }
    
   static testmethod void ROMobileCalendarHandlertest(){
    test.starttest();
      setup();
       system.runAs(resourceUser){
           datetime currentdt = system.now();
           Reservation__c R1 = new Reservation__c(Reason__c = ReservationReasonID, Startdatetime__c = system.now(), EndDateTime__c = system.now().addMinutes(30) );
			insert R1;
            Reservation__c R2 = new Reservation__c(Reason__c = ReservationReasonID, Startdatetime__c = system.now().addMinutes(30), EndDateTime__c = system.now().addMinutes(45) );
			insert R2;
           Reservation__c R3 = new Reservation__c(Reason__c = ReservationReasonID, Startdatetime__c = system.now().addMinutes(-30), EndDateTime__c = system.now() );
			insert R3;
            Reservation__c R4 = new Reservation__c(Reason__c = ReservationReasonID, Startdatetime__c = system.now().addMinutes(30), EndDateTime__c = system.now().addMinutes(55) );
			insert R4;
           system.debug('reservationsadmin'+adminuser.id );
           system.debug('reservations' +[Select Id,name,Startdatetime__c,EndDateTime__c,ReasonName__c,createdbyID FROM Reservation__c ]);
     	  String inputdate = string.valueof(currentdt.formatgmt('yyyy-MM-dd\'T\'HH:mm:ss.0000')); 
          List<roMobileCalendarHandler.response> samplerecords = roMobileCalendarHandler.getrecords(inputdate);
   		 List<ResourceOptimizerMobileCalendarConfig__mdt> filters =   roMobileCalendarHandler.getfilters(); 
          // system.debug(samplerecords.size());
       }  
    
       
    
    test.stoptest();   
}
}