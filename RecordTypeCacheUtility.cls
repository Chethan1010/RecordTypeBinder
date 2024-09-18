public class RecordTypeCacheUtility {
    // Create a RecordTypeCache__c object based on a new RecordType
    public static RecordTypeCache__c createRecordTypeCacheObject(RecordType newRecordType) {
        System.debug('entering into createRecordTypeCacheObject');
        RecordTypeCache__c cacheObject = new RecordTypeCache__c(
            Name = newRecordType.Name,
            DeveloperName__c = newRecordType.DeveloperName,
            ObjectName__c = newRecordType.SObjectType,
            StandardRT_Id__c = String.valueOf(newRecordType.id),
            Active__c = newRecordType.IsActive
        );
        return cacheObject;
    }
    // Check if a RecordType is in the cache list
    public static RecordTypeCache__c isRecordTypeInCache(RecordType recordType, List<RecordTypeCache__c> cacheList) {
        System.debug('entering into isRecordTypeInCache');
        for (RecordTypeCache__c cacheEntry : cacheList) {
            if (cacheEntry.StandardRT_Id__c == recordType.id) {
                return cacheEntry; // Found in cache
            }
        }
        return null; // Not found in cache
    }
    // Check if a RecordTypeCache__c object is in the list of new RecordTypes
    public static boolean isRecordTypeInList(RecordTypeCache__c cacheObject, List<RecordType> recordTypes) {
        System.debug('entering into isRecordTypeInList');
        for (RecordType recordType : recordTypes) {
            if (recordType.Id == cacheObject.StandardRT_Id__c) {
                return true; // Found in the list
            }
        }
        return false; // Not found in the list
    }
    // Define a method to send email notifications
    /* public static void sendEmailNotification(RecordType newRecordType, RecordTypeCache__c cachedRecordType) {
// Create an instance of your email handler class
YourEmailHandler emailHandler = new YourEmailHandler();
 
// Call the method in your email handler class to send the email
emailHandler.sendNotificationEmail(newRecordType, cachedRecordType);
}*/
    // Synchronize the cache with new RecordTypes
    public static void synchronizeCache() {
        try {
            List<RecordType> newRecordTypes = [SELECT Id, Name, DeveloperName, SobjectType,IsActive FROM RecordType];
            List<RecordTypeCache__c> cachedRecordTypes = [SELECT Id, Name, DeveloperName__c, ObjectName__c,StandardRT_Id__c,Active__c FROM RecordTypeCache__c];
            if (cachedRecordTypes.isEmpty()) {
                // If the cache is empty, insert all new RecordTypes as cache entries
                List<RecordTypeCache__c> cacheEntries = new List<RecordTypeCache__c>();
                for (RecordType newRecordType : newRecordTypes) {
                    RecordTypeCache__c cacheEntry = createRecordTypeCacheObject(newRecordType);
                    cacheEntry.Id = null;
                    cacheEntries.add(cacheEntry);
                }
                // Insert the cache entries without the Id field
                insert cacheEntries;
                System.debug('Cache entries inserted');
            }
            else {
                List<RecordTypeCache__c> addedRecordTypes = new List<RecordTypeCache__c>();
                List<RecordTypeCache__c> removedRecordTypes = new List<RecordTypeCache__c>();
                for (RecordType newRecordType : newRecordTypes) {
                    // Check if the RecordType is in the cache
                    RecordTypeCache__c cachedRecordType = isRecordTypeInCache(newRecordType, cachedRecordTypes);
                    if (cachedRecordType != null) {
                        if (cachedRecordType.Name != newRecordType.Name || cachedRecordType.DeveloperName__c != newRecordType.DeveloperName || cachedRecordType.Active__c != newRecordType.IsActive)  {
                            // Fields have changed, update the corresponding RecordTypeCache__c record
                            cachedRecordType.Name = newRecordType.Name;
                            cachedRecordType.DeveloperName__c = newRecordType.DeveloperName;
                            cachedRecordType.Active__c = newRecordType.IsActive;
                            update cachedRecordType; // Update the RecordTypeCache__c record
                            System.debug('Updated Cache Entry: ' + cachedRecordType);
                            sendEmailNotification(cachedRecordType,'Cache entry updated:');
                            System.debug('updated the record type and sent email successfully');
                            //send email notification
                            //sendEmailNotification(newRecordType, cachedRecordType);
                            // System.debug('Updated Cache Entry: ' + cachedRecordType);
                        }
                    } else {
                        // RecordType is not in the cache, insert it
                        RecordTypeCache__c cacheEntry = createRecordTypeCacheObject(newRecordType);
                        insert cacheEntry; // Insert the cache entry
                        System.debug('Added Cache Entry new: ' + cacheEntry);
                        sendEmailNotification(cacheEntry,'Cache entry inserted:');
                        System.debug('added new record type and sent email successfully');
                    }
                }
                for (RecordTypeCache__c cachedRecordType : cachedRecordTypes) {
                    if (!isRecordTypeInList(cachedRecordType, newRecordTypes)) {
                        // Cached RecordType is not in the new data, delete it from the cache
                        delete cachedRecordType; // Delete the cache entry
                        System.debug('Removed Cache Entry: ' + cachedRecordType);
                        sendEmailNotification(cachedRecordType,'Cache entry deleted:');
                        System.debug('after delete, email sent successfully');
                    }
                }
            }
        } catch (Exception e) {
            // Handle the exception, e.g., log the error, send an email, or perform other error-handling actions.
            System.debug('Exception caught: ' + e.getMessage());
        }

    }
    private static void sendEmailNotification(RecordTypeCache__c records, String action) {
        List<User> adminUsers = [SELECT Id, Email FROM User WHERE Profile.Name = 'System Administrator'];
        if (!adminUsers.isEmpty()){
            for (User adminUser : adminUsers) {
                // User adminUser = adminUsers[0];
                String adminEmail = adminUser.Email;
                System.debug('Admin Email: ' + adminEmail);
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[]{adminEmail});
                email.setSubject('Record Type ' + action + ' Notification');
                String emailBody = 'The following records had their Record Type ' + action + '\n\n';
                emailBody += 'Record Name: ' + records.Name + '\n';
                emailBody += 'Record Type: ' + records.DeveloperName__c + '\n\n';
                email.setPlainTextBody(emailBody);      
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            }
        }
        else {
            System.debug('No admin user found with the specified profile name');
        }
         List<ApexClass> apexClassList = [SELECT Name, Body, ApiVersion FROM ApexClass WHERE NamespacePrefix = null LIMIT 2];
        List<String> apexNameList = new List<String>();
        for(ApexClass cls : apexClassList){
            if(cls.Body.contains('recordTypeOperation')){
                apexNameList.add(cls.Name);
            }
            System.debug('Apex Classes List Contains Search String : ' + apexNameList);
        }
    }
    //-------------------------Reference List------------------------------
    Public void recordTypeOperation(){
        List<RecordType> newRecordTypes = [SELECT Id, Name, DeveloperName, SobjectType,IsActive FROM RecordType];
        List<RecordTypeCache__c> cachedRecordTypes = [SELECT Id, Name, DeveloperName__c, ObjectName__c,StandardRT_Id__c,Active__c FROM RecordTypeCache__c];
        // Compare RecordType data
    for (RecordType newRT : newRecordTypes) {
        for (RecordTypeCache__c cachedRT : cachedRecordTypes) {
            if (newRT.Name == cachedRT.Name && newRT.DeveloperName == cachedRT.DeveloperName__c && newRT.SobjectType == cachedRT.ObjectName__c && newRT.IsActive == cachedRT.Active__c) {
                // Match found, handle accordingly
                System.debug('Match found for RecordType: ' + newRT.Name);
            }
        }
    }
    }

}
