/************************************************************************ 
Author : Sukku
Details: 
    Purpose : MobileCalendarHandler is the apex class to fetch the data from MobileCalendarConfig__mdt and return 
              a wrapper response to mobilecalendar Web component. 
    Intial release date : August 01, 2020 

Powered by Cloud Sloka Pty Ltd. "www.cloudsloka.com.au"
*************************************************************************/
@isTest
public with sharing class roResourceAllocationTrigger_Test {
    
    public static Resource__c resource {get; set;}
    public static Resource__c resource2 {get; set;}
    public static Resource__c resource3 {get; set;}
    public static User dispatchUser {get; set;}
    public static User adminUser {get; set;}
    public static ResourceOptimizerConfig__c config {get; set;}

    static void setupData(){
        Id resOpSecurityResourceGroupRecTypeId = Schema.SObjectType.Resource_Optimizer_Security__c.getRecordTypeInfosByName().get('Resource Group').getRecordTypeId();
        //create dispatch user
        List<User> userList = roTestDataFactory.createUsers(2);
        Database.insert(userList);
        //assign permission set to user
        dispatchUser = userList[0];
        roTestDataFactory.assignPermissionSetToUsers(roTestDataFactory.permissionSetType.roDispatcher, new List<Id>{dispatchUser.Id});
        adminUser = userList[1];
        roTestDataFactory.assignPermissionSetToUsers(roTestDataFactory.permissionSetType.roAdmin, new List<Id>{adminUser.Id});

        system.runAs(adminUser){
            //insert org config
            config = new ResourceOptimizerConfig__c(Resource_Start_Hours__c = 9, Resource_Start_Minutes__c = 0, 
                Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0, Create_Efficiencies_For_Next_N_Days__c = 1);
            insert config;
            //create resource
            List<Resource__c> resourceList = roTestDataFactory.createresourceswithdefaultparent(3);
           // Database.insert(resourceList);
            resource = resourceList[0];
            resource2 = resourceList[1];
            resource3 = resourceList[2];
            //provide resource access to dispatch user by group
            Resource_Optimizer_Security__c security = new Resource_Optimizer_Security__c(Resource_Group__c = resource.Resource_Group__c, 
            User__c = dispatchUser.Id, RecordTypeId = resOpSecurityResourceGroupRecTypeId);
            Database.insert(security);
        }        
    }

    @isTest static void testResourceAvailableHours1(){
        setupData();
        
        System.runAs(adminUser){
            //keep only one user active for testing
            resource2.Active__c = false;
            resource3.Active__c = false;
            //set to delete any existing available hours
            resource.Recalculate_Available_hours__c = true;
            Database.update(new List<Resource__c>{resource, resource2, resource3});

            //create first utilization rec with batch method
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 15, Resource_Start_Minutes__c = 00, Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            update config;
            Test.startTest();
            roUtilizationRecordGeneratorBatch utilizationRecordGeneratorBatch = new roUtilizationRecordGeneratorBatch();
            Database.executeBatch(utilizationRecordGeneratorBatch);
            Test.stopTest();
            //check available hours 
            decimal availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(2, availableHours.round(), 'Available hours matched for resource');

            //duplicate slot
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 15, Resource_Start_Minutes__c = 00, Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            update config;
            roUtilizationRecordGeneratorBatch batchClass = new roUtilizationRecordGeneratorBatch();
            roUtilizationRecordsCreator.createAvailableHoursAndUtilizationsForResource(new set<Id>{resource.Id}, System.today(), 1, true);
            //check available hours 
            availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(2, availableHours.round());
        }
    }

    @isTest static void testResourceAvailableHours2(){
        setupData();
        System.runAs(adminUser){
            //keep only one user active for testing
            resource2.Active__c = false;
            resource3.Active__c = false;
            //set to delete any existing available hours
            resource.Recalculate_Available_hours__c = true;
            Database.update(new List<Resource__c>{resource, resource2, resource3});

            //create first utilization rec with batch method
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 15, Resource_Start_Minutes__c = 00, Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            update config;
            Test.startTest();
            roUtilizationRecordGeneratorBatch utilizationRecordGeneratorBatch = new roUtilizationRecordGeneratorBatch();
            Database.executeBatch(utilizationRecordGeneratorBatch);
            Test.stopTest();
            //check available hours 
            decimal availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(2, availableHours.round(), 'Available hours matched for resource');

            //consecutive start
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 13, Resource_Start_Minutes__c = 0, Resource_End_Hours__c = 15, Resource_End_Minutes__c = 0);
            update config;
            roUtilizationRecordsCreator.createAvailableHoursAndUtilizationsForResource(new set<Id>{resource.Id}, System.today(), 1, true);
            //check available hours 
            availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(4, availableHours.round());
        }
    }

    @isTest static void testResourceAvailableHours3(){
        setupData();
        System.runAs(adminUser){
            //keep only one user active for testing
            resource2.Active__c = false;
            resource3.Active__c = false;
            //set to delete any existing available hours
            resource.Recalculate_Available_hours__c = true;
            Database.update(new List<Resource__c>{resource, resource2, resource3});

            //create first utilization rec with batch method
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 15, Resource_Start_Minutes__c = 00, Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            update config;
            Test.startTest();
            roUtilizationRecordGeneratorBatch utilizationRecordGeneratorBatch = new roUtilizationRecordGeneratorBatch();
            Database.executeBatch(utilizationRecordGeneratorBatch);
            Test.stopTest();
            //check available hours 
            decimal availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(2, availableHours.round(), 'Available hours matched for resource');

            //consecutive end
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 17, Resource_Start_Minutes__c = 0, Resource_End_Hours__c = 19, Resource_End_Minutes__c = 0);
            update config;
            roUtilizationRecordsCreator.createAvailableHoursAndUtilizationsForResource(new set<Id>{resource.Id}, System.today(), 1, true);
            //check available hours 
            availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(4, availableHours.round());
        }
    }

    @isTest static void testResourceAvailableHours4(){
        setupData();
        System.runAs(adminUser){
            //keep only one user active for testing
            resource2.Active__c = false;
            resource3.Active__c = false;
            //set to delete any existing available hours
            resource.Recalculate_Available_hours__c = true;
            Database.update(new List<Resource__c>{resource, resource2, resource3});

            //create first utilization rec with batch method
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 15, Resource_Start_Minutes__c = 00, Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            update config;
            Test.startTest();
            roUtilizationRecordGeneratorBatch utilizationRecordGeneratorBatch = new roUtilizationRecordGeneratorBatch();
            Database.executeBatch(utilizationRecordGeneratorBatch);
            Test.stopTest();
            //check available hours 
            decimal availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(2, availableHours.round(), 'Available hours matched for resource');

            //overlapping start
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 15, Resource_Start_Minutes__c = 0, Resource_End_Hours__c = 19, Resource_End_Minutes__c = 0);
            update config;
            roUtilizationRecordsCreator.createAvailableHoursAndUtilizationsForResource(new set<Id>{resource.Id}, System.today(), 1, true);
            //check available hours 
            availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(4, availableHours.round());
        }
    }

    @isTest static void testResourceAvailableHours5(){
        setupData();
        System.runAs(adminUser){
            //keep only one user active for testing
            resource2.Active__c = false;
            resource3.Active__c = false;
            //set to delete any existing available hours
            resource.Recalculate_Available_hours__c = true;
            Database.update(new List<Resource__c>{resource, resource2, resource3});

            //create first utilization rec with batch method
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 15, Resource_Start_Minutes__c = 00, Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            update config;
            Test.startTest();
            roUtilizationRecordGeneratorBatch utilizationRecordGeneratorBatch = new roUtilizationRecordGeneratorBatch();
            Database.executeBatch(utilizationRecordGeneratorBatch);
            Test.stopTest();
            //check available hours 
            decimal availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(2, availableHours.round(), 'Available hours matched for resource');

            //overlapping end
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 13, Resource_Start_Minutes__c = 0, Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            update config;
            roUtilizationRecordsCreator.createAvailableHoursAndUtilizationsForResource(new set<Id>{resource.Id}, System.today(), 1, true);
            //check available hours 
            availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(4, availableHours.round());
        }
    }

    @isTest static void testResourceAvailableHours6(){
        setupData();
        System.runAs(adminUser){
            //keep only one user active for testing
            resource2.Active__c = false;
            resource3.Active__c = false;
            //set to delete any existing available hours
            resource.Recalculate_Available_hours__c = true;
            Database.update(new List<Resource__c>{resource, resource2, resource3});

            //create first utilization rec with batch method
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 15, Resource_Start_Minutes__c = 00, Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            update config;
            Test.startTest();
            roUtilizationRecordGeneratorBatch utilizationRecordGeneratorBatch = new roUtilizationRecordGeneratorBatch();
            Database.executeBatch(utilizationRecordGeneratorBatch);
            Test.stopTest();
            //check available hours 
            decimal availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(2, availableHours.round(), 'Available hours matched for resource');

            //start overlapping
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 14, Resource_Start_Minutes__c = 0, Resource_End_Hours__c = 16, Resource_End_Minutes__c = 0);
            update config;
            roUtilizationRecordsCreator.createAvailableHoursAndUtilizationsForResource(new set<Id>{resource.Id}, System.today(), 1, true);
            //check available hours 
            availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(3, availableHours.round());
        }
    }

    @isTest static void testResourceAvailableHours7(){
        setupData();
        System.runAs(adminUser){
            //keep only one user active for testing
            resource2.Active__c = false;
            resource3.Active__c = false;
            //set to delete any existing available hours
            resource.Recalculate_Available_hours__c = true;
            Database.update(new List<Resource__c>{resource, resource2, resource3});

            //create first utilization rec with batch method
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 15, Resource_Start_Minutes__c = 00, Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            update config;
            Test.startTest();
            roUtilizationRecordGeneratorBatch utilizationRecordGeneratorBatch = new roUtilizationRecordGeneratorBatch();
            Database.executeBatch(utilizationRecordGeneratorBatch);
            Test.stopTest();
            //check available hours 
            decimal availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(2, availableHours.round(), 'Available hours matched for resource');

            //end overlapping
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 16, Resource_Start_Minutes__c = 0, Resource_End_Hours__c = 18, Resource_End_Minutes__c = 0);
            update config;
            roUtilizationRecordsCreator.createAvailableHoursAndUtilizationsForResource(new set<Id>{resource.Id}, System.today(), 1, true);
            //check available hours 
            availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(3, availableHours.round());
        }
    }

    @isTest static void testResourceAvailableHours8(){
        setupData();
        System.runAs(adminUser){
            //keep only one user active for testing
            resource2.Active__c = false;
            resource3.Active__c = false;
            //set to delete any existing available hours
            resource.Recalculate_Available_hours__c = true;
            Database.update(new List<Resource__c>{resource, resource2, resource3});

            //create first utilization rec with batch method
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 15, Resource_Start_Minutes__c = 00, Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            update config;
            Test.startTest();
            roUtilizationRecordGeneratorBatch utilizationRecordGeneratorBatch = new roUtilizationRecordGeneratorBatch();
            Database.executeBatch(utilizationRecordGeneratorBatch);
            Test.stopTest();
            //check available hours 
            decimal availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(2, availableHours.round(), 'Available hours matched for resource');

            //independent before start
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 13, Resource_Start_Minutes__c = 0, Resource_End_Hours__c = 14, Resource_End_Minutes__c = 0);
            update config;
            roUtilizationRecordsCreator.createAvailableHoursAndUtilizationsForResource(new set<Id>{resource.Id}, System.today(), 1, true);
            //check available hours 
            availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(3, availableHours.round());
        }
    }

    @isTest static void testResourceAvailableHours9(){
        setupData();
        System.runAs(adminUser){
            //keep only one user active for testing
            resource2.Active__c = false;
            resource3.Active__c = false;
            //set to delete any existing available hours
            resource.Recalculate_Available_hours__c = true;
            Database.update(new List<Resource__c>{resource, resource2, resource3});

            //create first utilization rec with batch method
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 15, Resource_Start_Minutes__c = 00, Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            update config;
            Test.startTest();
            roUtilizationRecordGeneratorBatch utilizationRecordGeneratorBatch = new roUtilizationRecordGeneratorBatch();
            Database.executeBatch(utilizationRecordGeneratorBatch);
            test.stopTest();
            //check available hours 
            decimal availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(2, availableHours.round(), 'Available hours matched for resource');

            //independent after end
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 18, Resource_Start_Minutes__c = 0, Resource_End_Hours__c = 19, Resource_End_Minutes__c = 0);
            update config;
            roUtilizationRecordsCreator.createAvailableHoursAndUtilizationsForResource(new set<Id>{resource.Id}, System.today(), 1, true);
            //check available hours 
            availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(3, availableHours.round());
        }
    }

    @isTest static void testResourceAvailableHours10(){
        setupData();
        System.runAs(adminUser){
            //keep only one user active for testing
            resource2.Active__c = false;
            resource3.Active__c = false;
            //set to delete any existing available hours
            resource.Recalculate_Available_hours__c = true;
            Database.update(new List<Resource__c>{resource, resource2, resource3});

            //create first utilization rec with batch method
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 15, Resource_Start_Minutes__c = 00, Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            update config;
            Test.startTest();
            roUtilizationRecordGeneratorBatch utilizationRecordGeneratorBatch = new roUtilizationRecordGeneratorBatch();
            Database.executeBatch(utilizationRecordGeneratorBatch);
            test.stopTest();
            //check available hours 
            decimal availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(2, availableHours.round(), 'Available hours matched for resource');

            //subset
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 15, Resource_Start_Minutes__c = 30, Resource_End_Hours__c = 16, Resource_End_Minutes__c = 30);
            update config;
            roUtilizationRecordsCreator.createAvailableHoursAndUtilizationsForResource(new set<Id>{resource.Id}, System.today(), 1, true);
            //check available hours 
            availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(2, availableHours.round());
        }
    }

    @isTest static void testResourceAvailableHours11(){
        setupData();
        System.runAs(adminUser){
            //keep only one user active for testing
            resource2.Active__c = false;
            resource3.Active__c = false;
            //set to delete any existing available hours
            resource.Recalculate_Available_hours__c = true;
            Database.update(new List<Resource__c>{resource, resource2, resource3});

            //create first utilization rec with batch method
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 15, Resource_Start_Minutes__c = 00, Resource_End_Hours__c = 17, Resource_End_Minutes__c = 0);
            update config;
            test.startTest();
            roUtilizationRecordGeneratorBatch utilizationRecordGeneratorBatch = new roUtilizationRecordGeneratorBatch();
            Database.executeBatch(utilizationRecordGeneratorBatch);
            test.stopTest();
            //check available hours 
            decimal availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c, Available_Hours_Slots__c, (SELECT Id, 
            Start_time__c, End_Time__c FROM Resource_Available_Hours__r) FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(2, availableHours.round(), 'Available hours matched for resource');

            //override
            config = new ResourceOptimizerConfig__c(Id = config.Id, Resource_Start_Hours__c = 14, Resource_Start_Minutes__c = 00, Resource_End_Hours__c = 18, Resource_End_Minutes__c = 00);
            update config;
            roUtilizationRecordsCreator.createAvailableHoursAndUtilizationsForResource(new set<Id>{resource.Id}, System.today(), 1, true);
            //check available hours 
            availableHours = 0;
            for(Resource_Utilization__c rut :[SELECT Id, Available_hours__c, Available_Hours_Slots__c, (SELECT Id, 
            Start_time__c, End_Time__c FROM Resource_Available_Hours__r)  FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
            AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]){
                availableHours += rut.Available_hours__c;
            }
            system.assertEquals(4, availableHours.round());
        }
    }

    @isTest static void testResourceAllocationBeforeInsertTriggerInsertUpdateScenario1(){
        setupData();
        Test.startTest();
        system.runAs(dispatchUser){
            //create new allocation for the resource as dispatcher
            Resource_Allocation__c resAlloc = new Resource_Allocation__c(Allocated_Start_DateTime__c = System.now(), 
            Allocated_End_Datetime__c = System.now().addhours(13), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc);
            system.debug('RAM DEBUG resAlloc details insert: Id '+resAlloc.Id+'start time '+resAlloc.Allocated_Start_DateTime__c+' end time '+resAlloc.Allocated_End_Datetime__c);
            //query utilization records created 
            Map<Id, Resource_Utilization__c> dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c, Utilization_Date__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            List<Resource_Utilization__c> weekEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.WEEKLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> monthEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.MONTHLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> quarterEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.QUARTERLYUTILIZATIONRECTYPEID];
            List<Resource_Available_Hours__c> resourceAvailableHours = [SELECT Id FROM Resource_Available_Hours__c WHERE Resource_Utilization__c 
                IN :dateEfficiencyRecType.keyset()];
            //assert statements against resource utilization records
            system.assertNotEquals(0, dateEfficiencyRecType.values().size(), 'Daily utilization record/s created');
            system.assertNotEquals(0, weekEfficiencyRecType.size(), 'Weekly utilization record/s created');
            system.assertNotEquals(0, monthEfficiencyRecType.size(), 'Monthly utilization record/s created');
            system.assertNotEquals(0, quarterEfficiencyRecType.size(), 'Quarterly utilization record/s created');
            system.assertNotEquals(0, resourceAvailableHours.size(), 'Resource Available hours record/s created');
            //assert statement against resource utilization percentage calculation
            Decimal availableHours = 0;
            Decimal workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                system.debug('RAM DEBUG res details: Id '+res.Id+' date '+res.Utilization_Date__c+' worked hours '+res.Worked_Hours__c+' booked slots '+res.Booked_Time_Slots__c);
                availableHours += res.Available_Hours__c;
                workedHours += res.Worked_Hours__c;
            }
            Integer dateDifference = (resAlloc.Allocated_Start_DateTime__c.dateGMT().daysBetween(resAlloc.Allocated_End_Datetime__c.dateGMT()) + 1) * 8;
            system.assertEquals(dateDifference, availableHours.round(), 'Available hours matched');
            system.assertEquals(13, workedHours.round(), 'Worked hours matched');

            //update resource allocation with end time
            resAlloc.Allocated_End_Datetime__c = resAlloc.Allocated_End_Datetime__c.addhours(1); 
            Database.update(resAlloc);
            system.debug('RAM DEBUG resAlloc details update: Id '+resAlloc.Id+'start time '+resAlloc.Allocated_Start_DateTime__c+' end time '+resAlloc.Allocated_End_Datetime__c);
            //query and check values for updated utilization record
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c, Utilization_Date__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                system.debug('RAM DEBUG res details updated: Id '+res.Id+' date '+res.Utilization_Date__c+' worked hours '+res.Worked_Hours__c+' booked slots '+res.Booked_Time_Slots__c);
                workedHours += res.Worked_Hours__c;
            }
            system.assertEquals(14, workedHours.round(), 'Worked hours matched after end time in utilization record updated');

            //update resource
            resAlloc.Resource__c = resource2.Id;
            Database.update(resAlloc);
            //query and check values for updated utilization record
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.assertEquals(0, workedHours.round(), 'Worked hours matched for old resource after resource in utilization record updated');
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource2.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.assertEquals(14, workedHours.round(), 'Worked hours matched for new resource after resource in utilization record updated');

            //check if no exceptions found
            List<Resource_Optimizer_Log__c> resourceExceptionLogs = [SELECT Id, Error_Message__c, Event__c, Stack_Trace__c, Exception_caught_by__c FROM Resource_Optimizer_Log__c];
            for(Resource_Optimizer_Log__c logs :resourceExceptionLogs){
                system.debug('EXCEPTION LOGS: '+logs);
            }
            system.assertEquals(0, resourceExceptionLogs.size(), 'Exception records not created.'); 
        }
        Test.stopTest();

    }

    @isTest static void testResourceAllocationBeforeInsertTriggerInsertUpdateScenario2(){
        setupData();
        Test.startTest();
        system.runAs(dispatchUser){
            //create new allocation for the resource as dispatcher
            Resource_Allocation__c resAlloc = new Resource_Allocation__c(Allocated_Start_DateTime__c = System.now(), 
            Allocated_End_Datetime__c = System.now().addhours(13), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc);
            system.debug('RAM DEBUG resAlloc details insert: Id '+resAlloc.Id+'start time '+resAlloc.Allocated_Start_DateTime__c+' end time '+resAlloc.Allocated_End_Datetime__c);
            //query utilization records created 
            Map<Id, Resource_Utilization__c> dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c, Utilization_Date__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            List<Resource_Utilization__c> weekEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.WEEKLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> monthEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.MONTHLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> quarterEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.QUARTERLYUTILIZATIONRECTYPEID];
            List<Resource_Available_Hours__c> resourceAvailableHours = [SELECT Id FROM Resource_Available_Hours__c WHERE Resource_Utilization__c 
                IN :dateEfficiencyRecType.keyset()];
            //assert statements against resource utilization records
            system.assertNotEquals(0, dateEfficiencyRecType.values().size(), 'Daily utilization record/s created');
            system.assertNotEquals(0, weekEfficiencyRecType.size(), 'Weekly utilization record/s created');
            system.assertNotEquals(0, monthEfficiencyRecType.size(), 'Monthly utilization record/s created');
            system.assertNotEquals(0, quarterEfficiencyRecType.size(), 'Quarterly utilization record/s created');
            system.assertNotEquals(0, resourceAvailableHours.size(), 'Resource Available hours record/s created');
            //assert statement against resource utilization percentage calculation
            Decimal availableHours = 0;
            Decimal workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                system.debug('RAM DEBUG res details: Id '+res.Id+' date '+res.Utilization_Date__c+' worked hours '+res.Worked_Hours__c+' booked slots '+res.Booked_Time_Slots__c);
                availableHours += res.Available_Hours__c;
                workedHours += res.Worked_Hours__c;
            }
            Integer dateDifference = (resAlloc.Allocated_Start_DateTime__c.dateGMT().daysBetween(resAlloc.Allocated_End_Datetime__c.dateGMT()) + 1) * 8;
            system.assertEquals(dateDifference, availableHours.round(), 'Available hours matched');
            system.assertEquals(13, workedHours.round(), 'Worked hours matched');

            //update resource allocation's end time and resource
            resAlloc.Resource__c = resource3.Id;
            resAlloc.Allocated_End_Datetime__c = resAlloc.Allocated_End_Datetime__c.addhours(-1);
            Database.update(resAlloc);
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource3.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.assertEquals(12, workedHours.round(), 'Worked hours matched for after utilization record updated');

            //create new allocation and update for the resource as dispatcher
            Resource_Allocation__c resAllocNew = new Resource_Allocation__c(Allocated_Start_DateTime__c = resAlloc.Allocated_End_Datetime__c.addhours(2), 
            Allocated_End_Datetime__c = resAlloc.Allocated_End_Datetime__c.addhours(4), Calculate_Utilization__c = true, 
            Resource__c = resource3.Id);
            resAlloc.Allocated_End_Datetime__c = resAlloc.Allocated_End_Datetime__c.addhours(1);
            Database.upsert(new List<Resource_Allocation__c>{resAllocNew, resAlloc});
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource3.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.assertEquals(15, workedHours.round(), 'Worked hours matched for after utilization record updated');

            //check if no exceptions found
            List<Resource_Optimizer_Log__c> resourceExceptionLogs = [SELECT Id, Error_Message__c, Event__c, Stack_Trace__c, Exception_caught_by__c FROM Resource_Optimizer_Log__c];
            for(Resource_Optimizer_Log__c logs :resourceExceptionLogs){
                system.debug('EXCEPTION LOGS: '+logs);
            }
            system.assertEquals(0, resourceExceptionLogs.size(), 'Exception records not created.'); 
        }
        Test.stopTest();

    }

    @isTest static void testAddingNewAllocations1(){
        setupData();
        Test.startTest();
        system.runAs(dispatchUser){
            //create new allocation for the resource as dispatcher
            Resource_Allocation__c resAlloc = new Resource_Allocation__c(Allocated_Start_DateTime__c = System.now(), 
            Allocated_End_Datetime__c = System.now().addhours(2), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc);
            system.debug('RAM DEBUG resAlloc details insert: Id '+resAlloc.Id+'start time '+resAlloc.Allocated_Start_DateTime__c+' end time '+resAlloc.Allocated_End_Datetime__c);
            //query utilization records created 
            Map<Id, Resource_Utilization__c> dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c, Utilization_Date__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            List<Resource_Utilization__c> weekEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.WEEKLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> monthEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.MONTHLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> quarterEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.QUARTERLYUTILIZATIONRECTYPEID];
            List<Resource_Available_Hours__c> resourceAvailableHours = [SELECT Id FROM Resource_Available_Hours__c WHERE Resource_Utilization__c 
                IN :dateEfficiencyRecType.keyset()];
            //assert statements against resource utilization records
            system.assertNotEquals(0, dateEfficiencyRecType.values().size(), 'Daily utilization record/s created');
            system.assertNotEquals(0, weekEfficiencyRecType.size(), 'Weekly utilization record/s created');
            system.assertNotEquals(0, monthEfficiencyRecType.size(), 'Monthly utilization record/s created');
            system.assertNotEquals(0, quarterEfficiencyRecType.size(), 'Quarterly utilization record/s created');
            system.assertNotEquals(0, resourceAvailableHours.size(), 'Resource Available hours record/s created');
            //assert statement against resource utilization percentage calculation
            Decimal availableHours = 0;
            Decimal workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                system.debug('RAM DEBUG res details: Id '+res.Id+' date '+res.Utilization_Date__c+' worked hours '+res.Worked_Hours__c+' booked slots '+res.Booked_Time_Slots__c);
                availableHours += res.Available_Hours__c;
                workedHours += res.Worked_Hours__c;
            }
            Integer dateDifference = (resAlloc.Allocated_Start_DateTime__c.dateGMT().daysBetween(resAlloc.Allocated_End_Datetime__c.dateGMT()) + 1) * 8;
            system.assertEquals(dateDifference, availableHours.round(), 'Available hours matched');
            system.assertEquals(2, workedHours.round(), 'Worked hours matched');

            //new allocation same slot
            Resource_Allocation__c resAlloc1 = new Resource_Allocation__c(Allocated_Start_DateTime__c = resAlloc.Allocated_Start_DateTime__c, 
            Allocated_End_Datetime__c = resAlloc.Allocated_End_Datetime__c, Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc1);
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.assertEquals(2, workedHours.round(), 'Worked hours matched for after utilization record updated');

            //check if no exceptions found
            List<Resource_Optimizer_Log__c> resourceExceptionLogs = [SELECT Id, Error_Message__c, Event__c, Stack_Trace__c, Exception_caught_by__c FROM Resource_Optimizer_Log__c];
            for(Resource_Optimizer_Log__c logs :resourceExceptionLogs){
                system.debug('EXCEPTION LOGS: '+logs);
            }
            system.assertEquals(0, resourceExceptionLogs.size(), 'Exception records not created.'); 
        }
        Test.stopTest();

    }

    @isTest static void testAddingNewAllocations2(){
        setupData();
        Test.startTest();
        system.runAs(dispatchUser){
            //create new allocation for the resource as dispatcher
            Resource_Allocation__c resAlloc = new Resource_Allocation__c(Allocated_Start_DateTime__c = System.now(), 
            Allocated_End_Datetime__c = System.now().addhours(2), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc);
            system.debug('RAM DEBUG resAlloc details insert: Id '+resAlloc.Id+'start time '+resAlloc.Allocated_Start_DateTime__c+' end time '+resAlloc.Allocated_End_Datetime__c);
            //query utilization records created 
            Map<Id, Resource_Utilization__c> dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c, Utilization_Date__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            List<Resource_Utilization__c> weekEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.WEEKLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> monthEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.MONTHLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> quarterEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.QUARTERLYUTILIZATIONRECTYPEID];
            List<Resource_Available_Hours__c> resourceAvailableHours = [SELECT Id FROM Resource_Available_Hours__c WHERE Resource_Utilization__c 
                IN :dateEfficiencyRecType.keyset()];
            //assert statements against resource utilization records
            system.assertNotEquals(0, dateEfficiencyRecType.values().size(), 'Daily utilization record/s created');
            system.assertNotEquals(0, weekEfficiencyRecType.size(), 'Weekly utilization record/s created');
            system.assertNotEquals(0, monthEfficiencyRecType.size(), 'Monthly utilization record/s created');
            system.assertNotEquals(0, quarterEfficiencyRecType.size(), 'Quarterly utilization record/s created');
            system.assertNotEquals(0, resourceAvailableHours.size(), 'Resource Available hours record/s created');
            //assert statement against resource utilization percentage calculation
            Decimal availableHours = 0;
            Decimal workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                system.debug('RAM DEBUG res details: Id '+res.Id+' date '+res.Utilization_Date__c+' worked hours '+res.Worked_Hours__c+' booked slots '+res.Booked_Time_Slots__c);
                availableHours += res.Available_Hours__c;
                workedHours += res.Worked_Hours__c;
            }
            Integer dateDifference = (resAlloc.Allocated_Start_DateTime__c.dateGMT().daysBetween(resAlloc.Allocated_End_Datetime__c.dateGMT()) + 1) * 8;
            system.assertEquals(dateDifference, availableHours.round(), 'Available hours matched');
            system.assertEquals(2, workedHours.round(), 'Worked hours matched');

            //new allocation overlapping start hours
            Resource_Allocation__c resAlloc2 = new Resource_Allocation__c(Allocated_Start_DateTime__c = resAlloc.Allocated_Start_DateTime__c.addHours(-1), 
            Allocated_End_Datetime__c = resAlloc.Allocated_End_Datetime__c.addHours(-1), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc2);
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.assertEquals(3, workedHours.round(), 'Worked hours matched for after utilization record updated');

            //check if no exceptions found
            List<Resource_Optimizer_Log__c> resourceExceptionLogs = [SELECT Id, Error_Message__c, Event__c, Stack_Trace__c, Exception_caught_by__c FROM Resource_Optimizer_Log__c];
            for(Resource_Optimizer_Log__c logs :resourceExceptionLogs){
                system.debug('EXCEPTION LOGS: '+logs);
            }
            system.assertEquals(0, resourceExceptionLogs.size(), 'Exception records not created.'); 
        }
        Test.stopTest();

    }

    @isTest static void testAddingNewAllocations3(){
        setupData();
        Test.startTest();
        system.runAs(dispatchUser){
            //create new allocation for the resource as dispatcher
            Resource_Allocation__c resAlloc = new Resource_Allocation__c(Allocated_Start_DateTime__c = System.now(), 
            Allocated_End_Datetime__c = System.now().addhours(2), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc);
            system.debug('RAM DEBUG resAlloc details insert: Id '+resAlloc.Id+'start time '+resAlloc.Allocated_Start_DateTime__c+' end time '+resAlloc.Allocated_End_Datetime__c);
            //query utilization records created 
            Map<Id, Resource_Utilization__c> dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c, Utilization_Date__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            List<Resource_Utilization__c> weekEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.WEEKLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> monthEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.MONTHLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> quarterEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.QUARTERLYUTILIZATIONRECTYPEID];
            List<Resource_Available_Hours__c> resourceAvailableHours = [SELECT Id FROM Resource_Available_Hours__c WHERE Resource_Utilization__c 
                IN :dateEfficiencyRecType.keyset()];
            //assert statements against resource utilization records
            system.assertNotEquals(0, dateEfficiencyRecType.values().size(), 'Daily utilization record/s created');
            system.assertNotEquals(0, weekEfficiencyRecType.size(), 'Weekly utilization record/s created');
            system.assertNotEquals(0, monthEfficiencyRecType.size(), 'Monthly utilization record/s created');
            system.assertNotEquals(0, quarterEfficiencyRecType.size(), 'Quarterly utilization record/s created');
            system.assertNotEquals(0, resourceAvailableHours.size(), 'Resource Available hours record/s created');
            //assert statement against resource utilization percentage calculation
            Decimal availableHours = 0;
            Decimal workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                system.debug('RAM DEBUG res details: Id '+res.Id+' date '+res.Utilization_Date__c+' worked hours '+res.Worked_Hours__c+' booked slots '+res.Booked_Time_Slots__c);
                availableHours += res.Available_Hours__c;
                workedHours += res.Worked_Hours__c;
            }
            Integer dateDifference = (resAlloc.Allocated_Start_DateTime__c.dateGMT().daysBetween(resAlloc.Allocated_End_Datetime__c.dateGMT()) + 1) * 8;
            system.assertEquals(dateDifference, availableHours.round(), 'Available hours matched');
            system.assertEquals(2, workedHours.round(), 'Worked hours matched');

            //new allocation overlapping end hours
            Resource_Allocation__c resAlloc3 = new Resource_Allocation__c(Allocated_Start_DateTime__c = resAlloc.Allocated_Start_DateTime__c.addHours(1), 
            Allocated_End_Datetime__c = resAlloc.Allocated_End_Datetime__c.addHours(1), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc3);
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.assertEquals(3, workedHours.round(), 'Worked hours matched for after utilization record updated');

            //new allocation overlapping end hours
            Resource_Allocation__c resAlloc3a = new Resource_Allocation__c(Allocated_Start_DateTime__c = resAlloc.Allocated_Start_DateTime__c.addHours(1), 
            Allocated_End_Datetime__c = resAlloc.Allocated_End_Datetime__c.addHours(1), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc3a);
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.assertEquals(3, workedHours.round(), 'Worked hours matched for after utilization record updated');

            //check if no exceptions found
            List<Resource_Optimizer_Log__c> resourceExceptionLogs = [SELECT Id, Error_Message__c, Event__c, Stack_Trace__c, Exception_caught_by__c FROM Resource_Optimizer_Log__c];
            for(Resource_Optimizer_Log__c logs :resourceExceptionLogs){
                system.debug('EXCEPTION LOGS: '+logs);
            }
            system.assertEquals(0, resourceExceptionLogs.size(), 'Exception records not created.'); 
        }
        Test.stopTest();

    }

    @isTest static void testAddingNewAllocations4(){
        setupData();
        Test.startTest();
        system.runAs(dispatchUser){
            //create new allocation for the resource as dispatcher
            Resource_Allocation__c resAlloc = new Resource_Allocation__c(Allocated_Start_DateTime__c = System.now(), 
            Allocated_End_Datetime__c = System.now().addhours(2), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc);
            system.debug('RAM DEBUG resAlloc details insert: Id '+resAlloc.Id+'start time '+resAlloc.Allocated_Start_DateTime__c+' end time '+resAlloc.Allocated_End_Datetime__c);
            //query utilization records created 
            Map<Id, Resource_Utilization__c> dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c, Utilization_Date__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            List<Resource_Utilization__c> weekEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.WEEKLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> monthEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.MONTHLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> quarterEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.QUARTERLYUTILIZATIONRECTYPEID];
            List<Resource_Available_Hours__c> resourceAvailableHours = [SELECT Id FROM Resource_Available_Hours__c WHERE Resource_Utilization__c 
                IN :dateEfficiencyRecType.keyset()];
            //assert statements against resource utilization records
            system.assertNotEquals(0, dateEfficiencyRecType.values().size(), 'Daily utilization record/s created');
            system.assertNotEquals(0, weekEfficiencyRecType.size(), 'Weekly utilization record/s created');
            system.assertNotEquals(0, monthEfficiencyRecType.size(), 'Monthly utilization record/s created');
            system.assertNotEquals(0, quarterEfficiencyRecType.size(), 'Quarterly utilization record/s created');
            system.assertNotEquals(0, resourceAvailableHours.size(), 'Resource Available hours record/s created');
            //assert statement against resource utilization percentage calculation
            Decimal availableHours = 0;
            Decimal workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                system.debug('RAM DEBUG res details: Id '+res.Id+' date '+res.Utilization_Date__c+' worked hours '+res.Worked_Hours__c+' booked slots '+res.Booked_Time_Slots__c);
                availableHours += res.Available_Hours__c;
                workedHours += res.Worked_Hours__c;
            }
            Integer dateDifference = (resAlloc.Allocated_Start_DateTime__c.dateGMT().daysBetween(resAlloc.Allocated_End_Datetime__c.dateGMT()) + 1) * 8;
            system.assertEquals(dateDifference, availableHours.round(), 'Available hours matched');
            system.assertEquals(2, workedHours.round(), 'Worked hours matched');

            //new allocation increase end hours
            Resource_Allocation__c resAlloc4 = new Resource_Allocation__c(Allocated_Start_DateTime__c = resAlloc.Allocated_Start_DateTime__c, 
            Allocated_End_Datetime__c = resAlloc.Allocated_End_Datetime__c.addHours(1), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc4);
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.assertEquals(3, workedHours.round(), 'Worked hours matched for after utilization record updated');

            //check if no exceptions found
            List<Resource_Optimizer_Log__c> resourceExceptionLogs = [SELECT Id, Error_Message__c, Event__c, Stack_Trace__c, Exception_caught_by__c FROM Resource_Optimizer_Log__c];
            for(Resource_Optimizer_Log__c logs :resourceExceptionLogs){
                system.debug('EXCEPTION LOGS: '+logs);
            }
            system.assertEquals(0, resourceExceptionLogs.size(), 'Exception records not created.'); 
        }
        Test.stopTest();

    }

    @isTest static void testAddingNewAllocations5(){
        setupData();
        Test.startTest();
        system.runAs(dispatchUser){
            //create new allocation for the resource as dispatcher
            Resource_Allocation__c resAlloc = new Resource_Allocation__c(Allocated_Start_DateTime__c = System.now(), 
            Allocated_End_Datetime__c = System.now().addhours(2), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc);
            system.debug('RAM DEBUG resAlloc details insert: Id '+resAlloc.Id+'start time '+resAlloc.Allocated_Start_DateTime__c+' end time '+resAlloc.Allocated_End_Datetime__c);
            //query utilization records created 
            Map<Id, Resource_Utilization__c> dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c, Utilization_Date__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            List<Resource_Utilization__c> weekEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.WEEKLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> monthEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.MONTHLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> quarterEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.QUARTERLYUTILIZATIONRECTYPEID];
            List<Resource_Available_Hours__c> resourceAvailableHours = [SELECT Id FROM Resource_Available_Hours__c WHERE Resource_Utilization__c 
                IN :dateEfficiencyRecType.keyset()];
            //assert statements against resource utilization records
            system.assertNotEquals(0, dateEfficiencyRecType.values().size(), 'Daily utilization record/s created');
            system.assertNotEquals(0, weekEfficiencyRecType.size(), 'Weekly utilization record/s created');
            system.assertNotEquals(0, monthEfficiencyRecType.size(), 'Monthly utilization record/s created');
            system.assertNotEquals(0, quarterEfficiencyRecType.size(), 'Quarterly utilization record/s created');
            system.assertNotEquals(0, resourceAvailableHours.size(), 'Resource Available hours record/s created');
            //assert statement against resource utilization percentage calculation
            Decimal availableHours = 0;
            Decimal workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                system.debug('RAM DEBUG res details: Id '+res.Id+' date '+res.Utilization_Date__c+' worked hours '+res.Worked_Hours__c+' booked slots '+res.Booked_Time_Slots__c);
                availableHours += res.Available_Hours__c;
                workedHours += res.Worked_Hours__c;
            }
            Integer dateDifference = (resAlloc.Allocated_Start_DateTime__c.dateGMT().daysBetween(resAlloc.Allocated_End_Datetime__c.dateGMT()) + 1) * 8;
            system.assertEquals(dateDifference, availableHours.round(), 'Available hours matched');
            system.assertEquals(2, workedHours.round(), 'Worked hours matched');

            //new allocation decrease start hours
            Resource_Allocation__c resAlloc5 = new Resource_Allocation__c(Allocated_Start_DateTime__c = resAlloc.Allocated_Start_DateTime__c.addHours(-1), 
            Allocated_End_Datetime__c = resAlloc.Allocated_End_Datetime__c, Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc5);
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.assertEquals(3, workedHours.round(), 'Worked hours matched for after utilization record updated');

            //new allocation decrease end hours
            Resource_Allocation__c resAlloc6 = new Resource_Allocation__c(Allocated_Start_DateTime__c = resAlloc.Allocated_Start_DateTime__c, 
            Allocated_End_Datetime__c = resAlloc.Allocated_End_Datetime__c.addHours(-1), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc6);
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.debug('resAlloc6 '+workedHours);
            //system.assertEquals(4, workedHours.round(), 'Worked hours matched for after utilization record updated');

            //new allocation increase start hours
            Resource_Allocation__c resAlloc7 = new Resource_Allocation__c(Allocated_Start_DateTime__c = resAlloc.Allocated_Start_DateTime__c.addHours(1), 
            Allocated_End_Datetime__c = resAlloc.Allocated_End_Datetime__c, Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc7);
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.debug('resAlloc7 '+workedHours);
            //system.assertEquals(4, workedHours.round(), 'Worked hours matched for after utilization record updated');

            //new allocation no overlap before start hours
            Resource_Allocation__c resAlloc8 = new Resource_Allocation__c(Allocated_Start_DateTime__c = resAlloc.Allocated_Start_DateTime__c.addHours(-2), 
            Allocated_End_Datetime__c = resAlloc.Allocated_Start_DateTime__c.addHours(-1), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc8);
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.debug('resAlloc8 '+workedHours);
            //system.assertEquals(4, workedHours.round(), 'Worked hours matched for after utilization record updated');

            //new allocation no overlap after end hours
            Resource_Allocation__c resAlloc9 = new Resource_Allocation__c(Allocated_Start_DateTime__c = resAlloc.Allocated_End_Datetime__c.addHours(1), 
            Allocated_End_Datetime__c = resAlloc.Allocated_End_Datetime__c.addHours(2), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc9);
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.debug('resAlloc9 '+workedHours);
            //system.assertEquals(4, workedHours.round(), 'Worked hours matched for after utilization record updated');            

            //check if no exceptions found
            List<Resource_Optimizer_Log__c> resourceExceptionLogs = [SELECT Id, Error_Message__c, Event__c, Stack_Trace__c, Exception_caught_by__c FROM Resource_Optimizer_Log__c];
            for(Resource_Optimizer_Log__c logs :resourceExceptionLogs){
                system.debug('EXCEPTION LOGS: '+logs);
            }
            system.assertEquals(0, resourceExceptionLogs.size(), 'Exception records not created.'); 
        }
        Test.stopTest();

    }

    @isTest static void testAddingNewAllocations6(){
        setupData();
        Test.startTest();
        system.runAs(dispatchUser){
            //create new allocation for the resource as dispatcher
            Resource_Allocation__c resAlloc = new Resource_Allocation__c(Allocated_Start_DateTime__c = System.now(), 
            Allocated_End_Datetime__c = System.now().addhours(2), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc);
            system.debug('RAM DEBUG resAlloc details insert: Id '+resAlloc.Id+'start time '+resAlloc.Allocated_Start_DateTime__c+' end time '+resAlloc.Allocated_End_Datetime__c);
            //query utilization records created 
            Map<Id, Resource_Utilization__c> dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c, Utilization_Date__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            List<Resource_Utilization__c> weekEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.WEEKLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> monthEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.MONTHLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> quarterEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.QUARTERLYUTILIZATIONRECTYPEID];
            List<Resource_Available_Hours__c> resourceAvailableHours = [SELECT Id FROM Resource_Available_Hours__c WHERE Resource_Utilization__c 
                IN :dateEfficiencyRecType.keyset()];
            //assert statements against resource utilization records
            system.assertNotEquals(0, dateEfficiencyRecType.values().size(), 'Daily utilization record/s created');
            system.assertNotEquals(0, weekEfficiencyRecType.size(), 'Weekly utilization record/s created');
            system.assertNotEquals(0, monthEfficiencyRecType.size(), 'Monthly utilization record/s created');
            system.assertNotEquals(0, quarterEfficiencyRecType.size(), 'Quarterly utilization record/s created');
            system.assertNotEquals(0, resourceAvailableHours.size(), 'Resource Available hours record/s created');
            //assert statement against resource utilization percentage calculation
            Decimal availableHours = 0;
            Decimal workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                system.debug('RAM DEBUG res details: Id '+res.Id+' date '+res.Utilization_Date__c+' worked hours '+res.Worked_Hours__c+' booked slots '+res.Booked_Time_Slots__c);
                availableHours += res.Available_Hours__c;
                workedHours += res.Worked_Hours__c;
            }
            Integer dateDifference = (resAlloc.Allocated_Start_DateTime__c.dateGMT().daysBetween(resAlloc.Allocated_End_Datetime__c.dateGMT()) + 1) * 8;
            system.assertEquals(dateDifference, availableHours.round(), 'Available hours matched');
            system.assertEquals(2, workedHours.round(), 'Worked hours matched');

            //new allocation decrease end hours
            Resource_Allocation__c resAlloc6 = new Resource_Allocation__c(Allocated_Start_DateTime__c = resAlloc.Allocated_Start_DateTime__c, 
            Allocated_End_Datetime__c = resAlloc.Allocated_End_Datetime__c.addHours(-1), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc6);
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.assertEquals(2, workedHours.round(), 'Worked hours matched for after utilization record updated');

            //check if no exceptions found
            List<Resource_Optimizer_Log__c> resourceExceptionLogs = [SELECT Id, Error_Message__c, Event__c, Stack_Trace__c, Exception_caught_by__c FROM Resource_Optimizer_Log__c];
            for(Resource_Optimizer_Log__c logs :resourceExceptionLogs){
                system.debug('EXCEPTION LOGS: '+logs);
            }
            system.assertEquals(0, resourceExceptionLogs.size(), 'Exception records not created.'); 
        }
        Test.stopTest();

    }

    @isTest static void testAddingNewAllocations7(){
        setupData();
        Test.startTest();
        system.runAs(dispatchUser){
            //create new allocation for the resource as dispatcher
            Resource_Allocation__c resAlloc = new Resource_Allocation__c(Allocated_Start_DateTime__c = System.now(), 
            Allocated_End_Datetime__c = System.now().addhours(2), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc);
            system.debug('RAM DEBUG resAlloc details insert: Id '+resAlloc.Id+'start time '+resAlloc.Allocated_Start_DateTime__c+' end time '+resAlloc.Allocated_End_Datetime__c);
            //query utilization records created 
            Map<Id, Resource_Utilization__c> dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c, Utilization_Date__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            List<Resource_Utilization__c> weekEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.WEEKLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> monthEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.MONTHLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> quarterEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.QUARTERLYUTILIZATIONRECTYPEID];
            List<Resource_Available_Hours__c> resourceAvailableHours = [SELECT Id FROM Resource_Available_Hours__c WHERE Resource_Utilization__c 
                IN :dateEfficiencyRecType.keyset()];
            //assert statements against resource utilization records
            system.assertNotEquals(0, dateEfficiencyRecType.values().size(), 'Daily utilization record/s created');
            system.assertNotEquals(0, weekEfficiencyRecType.size(), 'Weekly utilization record/s created');
            system.assertNotEquals(0, monthEfficiencyRecType.size(), 'Monthly utilization record/s created');
            system.assertNotEquals(0, quarterEfficiencyRecType.size(), 'Quarterly utilization record/s created');
            system.assertNotEquals(0, resourceAvailableHours.size(), 'Resource Available hours record/s created');
            //assert statement against resource utilization percentage calculation
            Decimal availableHours = 0;
            Decimal workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                system.debug('RAM DEBUG res details: Id '+res.Id+' date '+res.Utilization_Date__c+' worked hours '+res.Worked_Hours__c+' booked slots '+res.Booked_Time_Slots__c);
                availableHours += res.Available_Hours__c;
                workedHours += res.Worked_Hours__c;
            }
            Integer dateDifference = (resAlloc.Allocated_Start_DateTime__c.dateGMT().daysBetween(resAlloc.Allocated_End_Datetime__c.dateGMT()) + 1) * 8;
            system.assertEquals(dateDifference, availableHours.round(), 'Available hours matched');
            system.assertEquals(2, workedHours.round(), 'Worked hours matched');

            //new allocation increase start hours
            Resource_Allocation__c resAlloc7 = new Resource_Allocation__c(Allocated_Start_DateTime__c = resAlloc.Allocated_Start_DateTime__c.addHours(1), 
            Allocated_End_Datetime__c = resAlloc.Allocated_End_Datetime__c, Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc7);
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.assertEquals(2, workedHours.round(), 'Worked hours matched for after utilization record updated');

            //check if no exceptions found
            List<Resource_Optimizer_Log__c> resourceExceptionLogs = [SELECT Id, Error_Message__c, Event__c, Stack_Trace__c, Exception_caught_by__c FROM Resource_Optimizer_Log__c];
            for(Resource_Optimizer_Log__c logs :resourceExceptionLogs){
                system.debug('EXCEPTION LOGS: '+logs);
            }
            system.assertEquals(0, resourceExceptionLogs.size(), 'Exception records not created.'); 
        }
        Test.stopTest();

    }

    @isTest static void testAddingNewAllocations8(){
        setupData();
        Test.startTest();
        system.runAs(dispatchUser){
            //create new allocation for the resource as dispatcher
            Resource_Allocation__c resAlloc = new Resource_Allocation__c(Allocated_Start_DateTime__c = System.now(), 
            Allocated_End_Datetime__c = System.now().addhours(2), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc);
            system.debug('RAM DEBUG resAlloc details insert: Id '+resAlloc.Id+'start time '+resAlloc.Allocated_Start_DateTime__c+' end time '+resAlloc.Allocated_End_Datetime__c);
            //query utilization records created 
            Map<Id, Resource_Utilization__c> dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c, Utilization_Date__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            List<Resource_Utilization__c> weekEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.WEEKLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> monthEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.MONTHLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> quarterEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.QUARTERLYUTILIZATIONRECTYPEID];
            List<Resource_Available_Hours__c> resourceAvailableHours = [SELECT Id FROM Resource_Available_Hours__c WHERE Resource_Utilization__c 
                IN :dateEfficiencyRecType.keyset()];
            //assert statements against resource utilization records
            system.assertNotEquals(0, dateEfficiencyRecType.values().size(), 'Daily utilization record/s created');
            system.assertNotEquals(0, weekEfficiencyRecType.size(), 'Weekly utilization record/s created');
            system.assertNotEquals(0, monthEfficiencyRecType.size(), 'Monthly utilization record/s created');
            system.assertNotEquals(0, quarterEfficiencyRecType.size(), 'Quarterly utilization record/s created');
            system.assertNotEquals(0, resourceAvailableHours.size(), 'Resource Available hours record/s created');
            //assert statement against resource utilization percentage calculation
            Decimal availableHours = 0;
            Decimal workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                system.debug('RAM DEBUG res details: Id '+res.Id+' date '+res.Utilization_Date__c+' worked hours '+res.Worked_Hours__c+' booked slots '+res.Booked_Time_Slots__c);
                availableHours += res.Available_Hours__c;
                workedHours += res.Worked_Hours__c;
            }
            Integer dateDifference = (resAlloc.Allocated_Start_DateTime__c.dateGMT().daysBetween(resAlloc.Allocated_End_Datetime__c.dateGMT()) + 1) * 8;
            system.assertEquals(dateDifference, availableHours.round(), 'Available hours matched');
            system.assertEquals(2, workedHours.round(), 'Worked hours matched');

            //new allocation no overlap before start hours
            Resource_Allocation__c resAlloc8 = new Resource_Allocation__c(Allocated_Start_DateTime__c = resAlloc.Allocated_Start_DateTime__c.addHours(-2), 
            Allocated_End_Datetime__c = resAlloc.Allocated_Start_DateTime__c.addHours(-1), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc8);
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.assertEquals(3, workedHours.round(), 'Worked hours matched for after utilization record updated');

            //check if no exceptions found
            List<Resource_Optimizer_Log__c> resourceExceptionLogs = [SELECT Id, Error_Message__c, Event__c, Stack_Trace__c, Exception_caught_by__c FROM Resource_Optimizer_Log__c];
            for(Resource_Optimizer_Log__c logs :resourceExceptionLogs){
                system.debug('EXCEPTION LOGS: '+logs);
            }
            system.assertEquals(0, resourceExceptionLogs.size(), 'Exception records not created.'); 
        }
        Test.stopTest();

    }

    @isTest static void testAddingNewAllocations9(){
        setupData();
        Test.startTest();
        system.runAs(dispatchUser){
            //create new allocation for the resource as dispatcher
            Resource_Allocation__c resAlloc = new Resource_Allocation__c(Allocated_Start_DateTime__c = System.now(), 
            Allocated_End_Datetime__c = System.now().addhours(2), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc);
            system.debug('RAM DEBUG resAlloc details insert: Id '+resAlloc.Id+'start time '+resAlloc.Allocated_Start_DateTime__c+' end time '+resAlloc.Allocated_End_Datetime__c);
            //query utilization records created 
            Map<Id, Resource_Utilization__c> dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c, Utilization_Date__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            List<Resource_Utilization__c> weekEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.WEEKLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> monthEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.MONTHLYUTILIZATIONRECTYPEID];
            List<Resource_Utilization__c> quarterEfficiencyRecType = [SELECT Id, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id 
                AND RecordTypeId = :roTestDataFactory.QUARTERLYUTILIZATIONRECTYPEID];
            List<Resource_Available_Hours__c> resourceAvailableHours = [SELECT Id FROM Resource_Available_Hours__c WHERE Resource_Utilization__c 
                IN :dateEfficiencyRecType.keyset()];
            //assert statements against resource utilization records
            system.assertNotEquals(0, dateEfficiencyRecType.values().size(), 'Daily utilization record/s created');
            system.assertNotEquals(0, weekEfficiencyRecType.size(), 'Weekly utilization record/s created');
            system.assertNotEquals(0, monthEfficiencyRecType.size(), 'Monthly utilization record/s created');
            system.assertNotEquals(0, quarterEfficiencyRecType.size(), 'Quarterly utilization record/s created');
            system.assertNotEquals(0, resourceAvailableHours.size(), 'Resource Available hours record/s created');
            //assert statement against resource utilization percentage calculation
            Decimal availableHours = 0;
            Decimal workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                system.debug('RAM DEBUG res details: Id '+res.Id+' date '+res.Utilization_Date__c+' worked hours '+res.Worked_Hours__c+' booked slots '+res.Booked_Time_Slots__c);
                availableHours += res.Available_Hours__c;
                workedHours += res.Worked_Hours__c;
            }
            Integer dateDifference = (resAlloc.Allocated_Start_DateTime__c.dateGMT().daysBetween(resAlloc.Allocated_End_Datetime__c.dateGMT()) + 1) * 8;
            system.assertEquals(dateDifference, availableHours.round(), 'Available hours matched');
            system.assertEquals(2, workedHours.round(), 'Worked hours matched');

            //new allocation no overlap after end hours
            Resource_Allocation__c resAlloc9 = new Resource_Allocation__c(Allocated_Start_DateTime__c = resAlloc.Allocated_End_Datetime__c.addHours(1), 
            Allocated_End_Datetime__c = resAlloc.Allocated_End_Datetime__c.addHours(2), Calculate_Utilization__c = true, 
            Resource__c = resource.Id);
            Database.insert(resAlloc9);
            dateEfficiencyRecType = new Map<Id, Resource_Utilization__c>([SELECT Id, Booked_Time_Slots__c, 
                Available_Hours_Slots__c, Worked_Hours__c, Available_Hours__c, Utilization__c FROM Resource_Utilization__c WHERE Resource__c = :resource.Id
                AND RecordTypeId = :roTestDataFactory.DAILYUTILIZATIONRECTYPEID]);
            workedHours = 0;
            for(Resource_Utilization__c res :dateEfficiencyRecType.values()){
                workedHours += res.Worked_Hours__c;
            }
            system.assertEquals(3, workedHours.round(), 'Worked hours matched for after utilization record updated');            

            //check if no exceptions found
            List<Resource_Optimizer_Log__c> resourceExceptionLogs = [SELECT Id, Error_Message__c, Event__c, Stack_Trace__c, Exception_caught_by__c FROM Resource_Optimizer_Log__c];
            for(Resource_Optimizer_Log__c logs :resourceExceptionLogs){
                system.debug('EXCEPTION LOGS: '+logs);
            }
            system.assertEquals(0, resourceExceptionLogs.size(), 'Exception records not created.'); 
        }
        Test.stopTest();

    }
}