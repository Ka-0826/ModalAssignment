@isTest
public class PricebookEntryControllerTest {

    // テストデータをセットアップ
    static testMethod void setupData() {

        // 商品分類1の値を取得
        List<String> category1Values = new List<String>();
        for (Schema.PicklistEntry entry : Product2.Category1__c.getDescribe().getPicklistValues()) {
            category1Values.add(entry.getValue());
        }

        // 商品分類2の値を取得
        List<String> category2Values = new List<String>();
        for (Schema.PicklistEntry entry : Product2.Category2__c.getDescribe().getPicklistValues()) {
            category2Values.add(entry.getValue());
        }

        // デフォルト値を取得（選択肢がない場合に備えてリストの先頭を使用）
        String category1Value = category1Values.isEmpty() ? null : category1Values[0];
        String category2Value = category2Values.isEmpty() ? null : category2Values[0];
        
        // 価格表マスタ のテストデータ作成
        Pricebook__c pricebook = new Pricebook__c(
            Name = 'Test Pricebook',
            IsActive__c = true
        );
        insert pricebook;

        // 商品 のテストデータ作成
        Product2 product = new Product2(
            Name = 'Test Product',
            Category1__c = category1Value,
            Category2__c = category2Value,
            IsActive = true
        );
        insert product;

        // 価格表エントリマスタの作成
        PricebookEntryMaster__c pricebookEntryMaster = new PricebookEntryMaster__c(Pricebook__c = pricebook.Id, Product2__c = product.Id);
        insert pricebookEntryMaster;

        // 商品 のテストデータ作成
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            Category1__c = category1Value,
            Category2__c = category2Value,
            IsActive = true
        );
        insert testProduct;
    }

    // 1つ目のメソッド getPricebookEntries のテスト
    @isTest
    static void testGetPricebookEntries() {
        setupData();
        // テスト対象のPricebookIdを取得
        Pricebook__c pricebook = [SELECT Id FROM Pricebook__c WHERE Name = 'Test Pricebook' LIMIT 1];

        // テストメソッドの呼び出し
        Test.startTest();
        List<Map<String, Object>> result = PricebookEntryController.getPricebookEntries(pricebook.Id);
        Test.stopTest();

        // アサーション
        System.assertNotEquals(result, null, '価格表エントリの取得結果はnullではないこと');
        System.assert(result.size() > 0, '価格表エントリが1つ以上返されること');
    }

    // 2つ目のメソッド getCategoryOptions のテスト
    @isTest
    static void testGetCategoryOptions() {
        setupData();
        // テストメソッドの呼び出し
        Test.startTest();
        Map<String, List<String>> result = PricebookEntryController.getCategoryOptions();
        Test.stopTest();

        // アサーション
        System.assertNotEquals(result, null, 'カテゴリオプションがnullではないこと');
        System.assert(result.containsKey('category1'), 'カテゴリ1が結果に含まれていること');
        System.assert(result.containsKey('category2'), 'カテゴリ2が結果に含まれていること');
    }

    // createItems のテスト
    @isTest
    static void testCreateItems() {
        setupData();
        // 価格表エントリマスタの作成データを準備
        List<PricebookEntryMaster__c> finalData = new List<PricebookEntryMaster__c>();
        Pricebook__c pricebook = [SELECT Id FROM Pricebook__c WHERE Name = 'Test Pricebook' LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Product2' LIMIT 1];

        PricebookEntryMaster__c newItem = new PricebookEntryMaster__c(Pricebook__c = pricebook.Id, Product2__c = product.Id);
        finalData.add(newItem);

        // テストメソッドの呼び出し
        Test.startTest();
        List<PricebookEntryMaster__c> result = PricebookEntryController.createItems(finalData);
        Test.stopTest();

        // アサーション
        System.assertNotEquals(result, null, '作成された価格表エントリマスタがnullではないこと');
        System.assert(result.size() > 0, '価格表エントリマスタが1つ以上作成されること');
    }
}
