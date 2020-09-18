@IsTest
private class ContentDocumentLinkTriggerHandlerTest {

    @IsTest
    static void test_share_file_to_record() {

        // You may need to modify this
        // test to be able to insert an account
        // that meets your org's validation requirements.
        Account acct = new Account(
            Name = 'Test Account'
        );

        insert acct;

        Opportunity opp = new Opportunity(
            Name = 'This is a test',
            AccountId = acct.Id,
            StageName = 'Closed Won',
            CloseDate = Date.today()
        );

        insert opp;

        Invoice__c inv = new Invoice__c(
            Name = 'TEST-12345',
            Account__c = acct.Id,
            Opportunity__c = opp.Id
        );

        insert inv;

        // create an invoice, unshared to any record
        ContentVersion file = new ContentVersion(
            Title = 'Invoice TEST-12345',
            PathOnClient = 'file.txt',
            VersionData = Blob.valueOf( 'Hello World' )
        );

        insert file;

        // query the generated content document id
        file = [ SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id ];

        Test.startTest();

        // share the file to the account
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = file.ContentDocumentId,
            LinkedEntityId = inv.Id,
            ShareType = 'I'
        );

        insert cdl; // trigger fires

                // create a second file, unshared to any record
                ContentVersion file2 = new ContentVersion(
                    Title = 'Invoice TEST-12345 V2',
                    PathOnClient = 'file.txt',
                    VersionData = Blob.valueOf( 'Hello World' )
                );
        
                insert file2;
        
                // query the generated content document id
                file2 = [ SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file2.Id ];
        
                // share the file to the account
                ContentDocumentLink cdl2 = new ContentDocumentLink(
                    ContentDocumentId = file2.ContentDocumentId,
                    LinkedEntityId = inv.Id,
                    ShareType = 'I'
                );

        insert cdl2; // trigger fires

                        // create a usage file, unshared to any record
                        ContentVersion file3 = new ContentVersion(
                            Title = 'Invoice with usage details TEST-12345',
                            PathOnClient = 'file.txt',
                            VersionData = Blob.valueOf( 'Hello World' )
                        );
                
                        insert file3;
                
                        // query the generated content document id
                        file3 = [ SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file3.Id ];
                
                        // share the file to the account
                        ContentDocumentLink cdl3 = new ContentDocumentLink(
                            ContentDocumentId = file3.ContentDocumentId,
                            LinkedEntityId = inv.Id,
                            ShareType = 'I'
                        );
        
                insert cdl3; // trigger fires

                                        // create another usage file, unshared to any record
                                        ContentVersion file4 = new ContentVersion(
                                            Title = 'Invoice with usage details TEST-12345 v2',
                                            PathOnClient = 'file.txt',
                                            VersionData = Blob.valueOf( 'Hello World' )
                                        );
                                
                                        insert file4;
                                
                                        // query the generated content document id
                                        file4 = [ SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file4.Id ];
                                
                                        // share the file to the account
                                        ContentDocumentLink cdl4 = new ContentDocumentLink(
                                            ContentDocumentId = file4.ContentDocumentId,
                                            LinkedEntityId = inv.Id,
                                            ShareType = 'I'
                                        );
                        
                                insert cdl4; // trigger fires

        Test.stopTest();


    }

}
