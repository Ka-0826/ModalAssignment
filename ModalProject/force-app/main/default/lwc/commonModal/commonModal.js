import { LightningElement, api } from 'lwc';

export default class CommonModal extends LightningElement {
    @api title;

    // クローズボタンの処理
    closeModal(event) {
        this.dispatchEvent(new CustomEvent('close'));
    }
}