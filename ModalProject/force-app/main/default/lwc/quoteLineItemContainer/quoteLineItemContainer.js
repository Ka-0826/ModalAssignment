import { LightningElement, track, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { showToast } from 'c/commonUtils';
import createLineItems from '@salesforce/apex/QuoteLineItemController.createLineItems';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';


export default class QuoteLineItemContainer extends LightningElement {
    @api recordId;                    // 見積レコードのID
    @track isFirstOpen = true;        // 商品選択画面
    @track isSecondOpen = false;      // 商品編集画面

    @api columns = [];                // 商品リスト
    @api hideCheckboxColumn = false;  // 画面のチェックボックス

    @api selectedProducts;            // 商品選択データ
    @track secondTableData = [];      // 編集用のデータ

    // クローズボタンの処理
    handleCloseModal() {
        console.log('モーダルが閉じられました');
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    connectedCallback() {
        console.log('recordId:', this.recordId);
    }

    // 商品選択画面で「次へ」ボタンを押したときproductSelectionを呼び出す処理
    handleNextFromChild(event) {
        if (!this.isFirstOpen) {
            console.error('c-product-selection は現在表示されていません');
            return;
        }
    
        const productSelection = this.template.querySelector('c-product-selection');
    
        if (!productSelection) {
            console.error('c-product-selection が見つかりません');
            return;
        }
    
        productSelection.handleNext(event);
    }

    // productSelectionから受け取った処理
    handleNext(event) {
        console.log('next clicked');
        // 配列をコピー
        this.selectedProducts = [...event.detail];
        this.isFirstOpen = false;
        this.isSecondOpen = true;
        this.hideCheckboxColumn1 = true;
        this.hideCheckboxColumn2 = true;

        // 選択された商品を secondTableData に渡す
        this.secondTableData = [...this.selectedProducts];
    }

    // 商品編集画面で「保存」ボタンを押したときproductEditorを呼び出す処理
    handleSaveFromChild(event) {
        if (!this.isSecondOpen) {
            console.error('c-product-editor は現在表示されていません');
            return;
        }
    
        const productEditor = this.template.querySelector('c-product-editor');
    
        if (!productEditor) {
            console.error('c-product-editor が見つかりません');
            return;
        }
        productEditor.handleSave(event);
    }

    // productEditorから受け取った処理
    handleSave(event) {
        // 配列をコピー
        this.secondTableData = [...event.detail];

        if (!Array.isArray(this.secondTableData) || this.secondTableData.length === 0) {
            this.dispatchEvent(showToast('警告', '商品を選択してください。', 'warning'));
            return;
        }

        // Apexへ送るデータ整形
        const finalData = this.secondTableData.map(item => ({
            Quote__c: this.recordId,
            Product2__c: item.ProductId,
            Name: '見積品目 ' + item.Name,
            Quantity__c: item.Quantity || 1,
            CostPrice__c: item.CostPrice,
            UnitPrice__c: item.UnitPrice,
            Discount__c: item.Discount || null,
        }));

        createLineItems({ finalData })
            .then(() => {
                this.dispatchEvent(showToast('成功', '見積品目が作成されました。', 'success'));

                // UI の標準関連リストを更新
                notifyRecordUpdateAvailable([{ recordId: this.recordId }]);

                // モーダルを閉じる
                this.dispatchEvent(new CloseActionScreenEvent());

                // 編集データをクリア
                this.secondTableData = [];

                // 子コンポーネントを取得・データ更新
                setTimeout(() => {
                    const productEditor = this.template.querySelector('c-product-editor');
                    if (productEditor) {
                        productEditor.refreshData();
                    } else {
                        console.error('productEditor が見つかりませんでした。');
                    }
                }, 100); 
            })
            .catch(error => {
                console.error('保存エラー:', error);
                this.dispatchEvent(showToast('エラー', '見積品目の作成に失敗しました。', 'error'));
            });
    }
}
