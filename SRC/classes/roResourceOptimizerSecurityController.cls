/*****************************************************************************************
 * Author : 				Santosh Rao Bompally 
 * Class Name : 			roResourceOptimizerSecurityController
 * Initial Authored Date : 	09 June 2020 
 * Purpose of Code : 		This Class handles all the DML operational Logicto be reffered on Resource_Optimizer_Security__c trigger. 
 * 
 * Features : 
 * 1: Create Unique ID (30 digit combination of userID and resourcegroupID) on the record before update.
 * 2: Creates Resource_Group__Share records for all the Resource_Optimizer_Security__c inserted.
 * 3: Deletes Resource_Group__Share records for all the Resource_Optimizer_Security__c deleted. 
 * 4: Locks Resource_Optimizer_Security__c records after creation. Allows to update only accesslevel 
 *  
 * Limitations : 
 * 
 * Doesnt Support Hierarchy creation
 * 
 ******************************************************************************************/
public class roResourceOptimizerSecurityController {
   
    
    Public Static Void CreateChildResourceOptimizerSecurityrecords(List<Resource_Optimizer_Security__c> RGSecuirtyRecords){
      
        List<Resource_Optimizer_Security__c> NewRGSecuirtyRecords = new List<Resource_Optimizer_Security__c>();
        Set<Id> GroupIds= new Set<Id>();
        
        for(Resource_Optimizer_Security__c RG : RGSecuirtyRecords){
            if(RG.Resource_Group__c != null){
              GroupIds.add(RG.Resource_Group__c);  
            }
         }
        
        if(GroupIds.size()>0){
            List<Resource_Group__c> ChildResourceGroups = [select id,Parent_Group__c From Resource_Group__c Where Parent_Group__c In :GroupIds];
        
            if(ChildResourceGroups.size()>0){
                
                for(Resource_Optimizer_Security__c RGS : RGSecuirtyRecords){
                    for(Resource_Group__c CRG : ChildResourceGroups){
                        if(CRG.Parent_Group__c == RGS.Resource_Group__c){
                           Resource_Optimizer_Security__c RGSTemp = new Resource_Optimizer_Security__c();
                            RGSTemp.Resource_Group__c = CRG.Id ;
                            RGSTemp.User__c = RGS.User__c ;
                            RGSTemp.Access_Level__c = RGS.Access_Level__c ;
                            
                            NewRGSecuirtyRecords.add(RGSTemp);
                        }
                    }
                    
                }
                
            }
        
        
        }
        
        if(NewRGSecuirtyRecords.size()>0){
            Database.insert(NewRGSecuirtyRecords, false);
        }
        
    }
    
    Public Static Void DeleteChildResourceOptimizerSecurityrecords(List<Resource_Optimizer_Security__c> RGSecuirtyRecords){
        List<Resource_Optimizer_Security__c> RGSecuirtyRecordstoDelete = new List<Resource_Optimizer_Security__c>();
        Set<Id> GroupIds= new Set<Id>();
        Set<String> UserAndGroupIds= new Set<string>();
        
        for(Resource_Optimizer_Security__c RG : RGSecuirtyRecords){
            GroupIds.add(RG.Resource_Group__c);
            UserAndGroupIds.add(RG.UniqueID__c);
        }
        
        if(GroupIds.size()>0){
             List<Resource_Optimizer_Security__c> RelatedRecordOptimizerSecurityrecords = [select id,Resource_Group__c,User__c,Resource_Group__r.Parent_Group__c From Resource_Optimizer_Security__c Where Resource_Group__r.Parent_Group__c In :GroupIds];
            if(RelatedRecordOptimizerSecurityrecords.size()>0){
                for(Resource_Optimizer_Security__c RGS : RelatedRecordOptimizerSecurityrecords){
                    if(UserAndGroupIds.contains(string.valueof(RGS.User__c).substring(0,15)+ string.valueof(RGS.Resource_Group__r.Parent_Group__c).substring(0,15))){
                        RGSecuirtyRecordstoDelete.add(RGS);
                    }
                }
            }
            
        }
        
        Delete RGSecuirtyRecordstoDelete ;
        
        
    }
    
    Public Static Void UpdateResourceOptimizerSecurityrecords(List<Resource_Optimizer_Security__c> RGSecuirtyRecords,Map<Id,Resource_Optimizer_Security__c> RGSecuirtyOldRecords){
      
        Set<Id> UserIds= new Set<Id>();
        Set<Id> GroupIds= new Set<Id>();
        Set<String> UserAndGroupIds= new Set<string>();
        Map<String,String> UpdateAccesslevel= new Map<String,String>();
        List<Resource_Group__Share> RGShares  = new List<Resource_Group__Share>();
        List<Resource_Optimizer_Security__c> FinalRelatedROSRecords = new List<Resource_Optimizer_Security__c>();
        List<Resource_Optimizer_Security__c> IntialRelatedROSRecords = new List<Resource_Optimizer_Security__c>();
        
        
        for(Resource_Optimizer_Security__c RG : RGSecuirtyRecords){
            
            if(RG.Resource_Group__c != null){
                if(RG.User__c != RGSecuirtyOldRecords.get(RG.id).User__c || RG.Resource_Group__c != RGSecuirtyOldRecords.get(RG.id).Resource_Group__c){
                RG.adderror('You cannot update User or Resource Group once a security record is created');
                 }
                
                if(RG.Access_Level__c != RGSecuirtyOldRecords.get(RG.id).Access_Level__c ){
                    UserIds.add(RG.User__c);
                    GroupIds.add(RG.Resource_Group__c);
                    UserAndGroupIds.add(RG.UniqueID__c);
                    UpdateAccesslevel.put(RG.UniqueID__c,RG.Access_Level__c);
                }
            }else{
                // Do Nothing
            }
            
        }
        
        if(GroupIds.size() > 0){
            for(Resource_Group__Share RGS : [select id,ParentId,UserOrGroupId from Resource_Group__Share where ParentId IN :GroupIds AND UserOrGroupId IN :UserIds]){
                if(UserAndGroupIds.contains(string.valueOf(RGS.UserOrGroupId).substring(0,15)+string.valueOf(RGS.ParentId).substring(0,15))){
                    RGS.AccessLevel = UpdateAccesslevel.get(string.valueOf(RGS.UserOrGroupId).substring(0,15)+string.valueOf(RGS.ParentId).substring(0,15));
                    RGShares.add(RGS);
                }
            }
            
            IntialRelatedROSRecords = [select id,user__c,resource_group__c,resource_group__r.parent_group__c from Resource_Optimizer_Security__c where resource_group__r.parent_group__c IN :GroupIds and user__c IN :UserIds];
        }
        
        for(Resource_Optimizer_Security__c ROS : IntialRelatedROSRecords){
            if(UserAndGroupIds.contains(string.valueOf(ROS.user__c).substring(0,15)+string.valueOf(ROS.resource_group__r.Parent_group__c).substring(0,15))){
                ROS.Access_Level__c = UpdateAccesslevel.get(string.valueOf(ROS.user__c).substring(0,15)+string.valueOf(ROS.resource_group__r.Parent_group__c).substring(0,15));
                FinalRelatedROSRecords.add(ROS);
            }
        }
        
        Update RGShares;
        Update FinalRelatedROSRecords ;
        
    }
    
    Public Static Void ValidateandCreateUniqueID(List<Resource_Optimizer_Security__c> RGSecuirtyRecords){
        
        for(Resource_Optimizer_Security__c RG : RGSecuirtyRecords){
           
            if(RG.Resource_Group__c != null && RG.Resource_Allocation_Parent__c != null){
               RG.adderror('You can create security records for either Resource Group or Resource Allocation Parent at once.'); 
            }else{
               if(RG.Resource_Group__c != null){
               RG.UniqueID__c = string.valueof(RG.User__c).substring(0,15)+ string.valueof(RG.Resource_Group__c).substring(0,15) ; 
            }
                if(RG.Resource_Allocation_Parent__c != null){
               RG.UniqueID__c = string.valueof(RG.User__c).substring(0,15)+ string.valueof(RG.Resource_Allocation_Parent__c).substring(0,15) ; 
            }
            }
                
            
            
        }
        
    }
    
    Public Static Void AssignResourcegroupSecurity(List<Resource_Optimizer_Security__c> RGSecuirtyRecords){
        
        List<Resource_Group__Share> RGShares  = new List<Resource_Group__Share>();

        Resource_Group__Share RGShare ;
        
        for(Resource_Optimizer_Security__c RGSecuirty : RGSecuirtyRecords){
          if(RGSecuirty.Resource_Group__c != null){
            RGShare = new Resource_Group__Share();
            
            // Set the ID of record being shared
            RGShare.ParentId = RGSecuirty.Resource_Group__c;
            
            // Set the ID of user or group being granted access
            RGShare.UserOrGroupId = RGSecuirty.User__c;
            
            // Set the access level
            RGShare.AccessLevel = RGSecuirty.Access_Level__c;
              
            RGShare.RowCause = 'Manual' ;
            
            // Add objects to list for insert
            RGShares.add(RGShare); 
            } 
            
         }
        
        Database.SaveResult[] lsr = Database.insert(RGShares,false);

    }
    
    Public Static Void AssignResourceAllocationParentSecurity(List<Resource_Optimizer_Security__c> RGSecuirtyRecords){
        
        List<Resource_Allocation_Parent__Share> RAPShares  = new List<Resource_Allocation_Parent__Share>();

        Resource_Allocation_Parent__Share RAPShare ;
        
        for(Resource_Optimizer_Security__c RGSecuirty : RGSecuirtyRecords){
          if(RGSecuirty.Resource_Allocation_Parent__c != null){
            RAPShare = new Resource_Allocation_Parent__Share();
            
            // Set the ID of record being shared
            RAPShare.ParentId = RGSecuirty.Resource_Allocation_Parent__c;
            
            // Set the ID of user or group being granted access
            RAPShare.UserOrGroupId = RGSecuirty.User__c;
            
            // Set the access level
            RAPShare.AccessLevel = RGSecuirty.Access_Level__c;
            
            // Add objects to list for insert
            RAPShares.add(RAPShare); 
            } 
            
         }
        
        Database.SaveResult[] lsr = Database.insert(RAPShares,false);

    }
    
    Public Static Void RemoveResourcegroupSecurity(List<Resource_Optimizer_Security__c> RGSecuirtyRecords){
        
        Set<Id> UserIds= new Set<Id>();
        Set<Id> GroupIds= new Set<Id>();
        Set<String> UserAndGroupIds= new Set<string>();
        
        For(Resource_Optimizer_Security__c RGSecuirty : RGSecuirtyRecords){
            if(RGSecuirty.Resource_Group__c != null){
            UserIds.add(RGSecuirty.User__c);
            GroupIds.add(RGSecuirty.Resource_Group__c);
            UserAndGroupIds.add(RGSecuirty.UniqueID__c);
            }
            
        }
        
        List<Resource_Group__Share> FinalSharestoDelete = new List<Resource_Group__Share>();
        
         List<Resource_Group__Share> InitialSharestoDelete = [select id,ParentId,UserOrGroupId from Resource_Group__Share where ParentId IN :GroupIds AND UserOrGroupId IN :UserIds];
        
        if(InitialSharestoDelete.size()>0){
            
            for(Resource_Group__Share RG : InitialSharestoDelete){
                
                if(UserAndGroupIds.contains(string.valueOf(RG.UserOrGroupId).substring(0,15)+string.valueOf(RG.ParentId).substring(0,15))){
                    FinalSharestoDelete.add(RG);
                }
            }
            
        }
        
        Delete FinalSharestoDelete ;
    }
    
    Public Static Void RemoveResourceAllocationParentSecurity(List<Resource_Optimizer_Security__c> RGSecuirtyRecords){
        
        Set<Id> UserIds= new Set<Id>();
        Set<Id> RAPIds= new Set<Id>();
        Set<String> UserAndRAPIds= new Set<string>();
        
        For(Resource_Optimizer_Security__c RGSecuirty : RGSecuirtyRecords){
            if(RGSecuirty.Resource_Allocation_Parent__c != null){
                UserIds.add(RGSecuirty.User__c);
                RAPIds.add(RGSecuirty.Resource_Allocation_Parent__c);
                UserAndRAPIds.add(RGSecuirty.UniqueID__c);  
            }
            
        }
        
        List<Resource_Allocation_Parent__Share> FinalSharestoDelete = new List<Resource_Allocation_Parent__Share>();
        
         List<Resource_Allocation_Parent__Share> InitialSharestoDelete = [select id,ParentId,UserOrGroupId from Resource_Allocation_Parent__Share where ParentId IN :RAPIds AND UserOrGroupId IN :UserIds];
        
        if(InitialSharestoDelete.size()>0){
            
            for(Resource_Allocation_Parent__Share RG : InitialSharestoDelete){
                
                if(UserAndRAPIds.contains(string.valueOf(RG.UserOrGroupId).substring(0,15)+string.valueOf(RG.ParentId).substring(0,15))){
                    FinalSharestoDelete.add(RG);
                }
            }
            
        }
        
        Delete FinalSharestoDelete ;
    }
    

}