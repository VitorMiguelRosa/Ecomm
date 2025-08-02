import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="products"
export default class extends Controller {
  static values = { size: String, product: Object }
  static targets = ["popup"]

  addToCart() {
    if (!this.sizeValue) {
      alert("Selecione um tamanho antes de adicionar ao carrinho!")
      return
    }

    const cart = localStorage.getItem("cart")
    let cartArray = cart ? JSON.parse(cart) : []
    const foundIndex = cartArray.findIndex(item => item.id === this.productValue.id && item.size === this.sizeValue)
    if (foundIndex >= 0) {
      cartArray[foundIndex].quantity = parseInt(cartArray[foundIndex].quantity) + 1
    } else {
      cartArray.push({
        id: this.productValue.id,
        name: this.productValue.name,
        price: this.productValue.price,
        size: this.sizeValue,
        quantity: 1
      })
    }
    localStorage.setItem("cart", JSON.stringify(cartArray))
    this.showPopup()
    console.log("product: ", this.productValue)
  }

  showPopup() {
    if (this.hasPopupTarget) {
      this.popupTarget.classList.remove("hidden")
    }
  }

  closePopup() {
    if (this.hasPopupTarget) {
      this.popupTarget.classList.add("hidden")
    }
  }

  selectSize(e) {
    this.sizeValue = e.target.value
    const selectedSizeEl = document.getElementById("selected-size")
    selectedSizeEl.innerText = `Selected Size: ${this.sizeValue}`
  }
}

