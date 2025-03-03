import { LightningElement, api, track, wire } from 'lwc';
import getQuotePricebookEntries from '@salesforce/apex/QuoteLineItemController.getQuotePricebookEntries';
import getQuoteHelper from '@salesforce/apex/QuoteLineItemController.getQuoteHelper';
import getCategoryOptions from '@salesforce/apex/QuoteLineItemController.getCategoryOptions';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';

const QUOTE_FIELDS = ['Quote__c.Id'];

export default class QuoteSelectionData extends LightningElement {
    @api recordId;                                   // 見積レコードのID
    @api get gridData() { return this._gridData; }   // 外部から _gridData を取得するためのメソッド
    @track quoteId;                                  // 見積レコードのID
    @track opportunityId;                            // 商談レコードのID
    @track pricebookId;                              // 価格表マスタレコードのID
    _gridData = [];                                  // 内部データ格納用の配列
    _options1 = [];                                  // 商品分類1を格納する配列
    _options2 = [];                                  // 商品分類2を格納する配列
    wiredQuoteResult;                                // refreshApex 用の変数
    
    @wire(getRecord, { recordId: '$recordId', fields: QUOTE_FIELDS })
    wiredQuote(result) {
        this.wiredQuoteResult = result; // refreshApex の対象として保存
        const { data, error } = result;

        if (data) {
            this.quoteId = data.fields.Id.value;

            if (this.quoteId) {
                this.loadProducts();
                this.loadCategoryOptions();
            }
        } else if (error) {
            console.error('データの取得に失敗しました。', error);
        }
    }

    //商品リストの取得
    async loadProducts() {
        try {
            // 見積ID、商談Id、価格表マスタIdを取得
            const dependencies = await getQuoteHelper({ quoteId: this.quoteId });
            if (!dependencies || !dependencies.opportunityId || !dependencies.pricebookId) {
                throw new Error('見積、商談、価格表マスタのいずれかの取得に失敗しました。');
            }

            // 価格表エントリを取得
            const data = await getQuotePricebookEntries({
                quoteId: this.quoteId,
                opportunityId: dependencies.opportunityId,
                pricebookId: dependencies.pricebookId
            });
            
            if (!data || !Array.isArray(data)) {
                throw new Error('取得データが配列ではありません。');
            }
            
            this.gridData = data.map(item => ({
                Id: item.Id,
                ProductId: item.Product2__c,
                Name: item.ProductName || '',
                ProductCode: item.ProductCode__c || '',
                IsActive: item.IsActive__c,
                CostPrice: item.CostPrice__c,
                UnitPrice: item.UnitPrice__c,
                Category1: item.Category1__c,
                Category2: item.Category2__c
            }));
        } catch (error) {
            console.error('商品データの取得エラー:', error);
        }
    }

    // 商品分類の取得
    async loadCategoryOptions() {
        try {
            const data = await getCategoryOptions();
            if (!data || !data.category1 || !data.category2) {
                throw new Error('商品分類データの取得に失敗しました。');
            }
            this.options1 = data.category1.map(value => ({ label: value, value }));
            this.options2 = data.category2.map(value => ({ label: value, value }));
        } catch (error) {
            console.error('商品分類の取得エラー:', error);
        }
    }

    get gridData() {
        return this._gridData;
    }

    get options1() {
        return this._options1;
    }

    get options2() {
        return this._options2;
    }

    set gridData(value) {
        this._gridData = [...value]; 
        this.dispatchEvent(new CustomEvent('gridupdate', { detail: this._gridData }));
    }

    set options1(value) {
        this._options1 = [...value]; 
    }
    
    set options2(value) {
        this._options2 = [...value]; 
    }

    // データのリフレッシュ
    @api
    refreshData() {
        return refreshApex(this.wiredQuoteResult)// データを最新化
            .then(() => {
                return this.loadProducts(); // 最新化後の商品データを取得
            })
            .catch(error => {
                console.error('refreshData() エラー:', error);
            });
    }
}