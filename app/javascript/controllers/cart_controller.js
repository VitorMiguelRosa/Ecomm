import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="cart"
export default class extends Controller {
  initialize() {

    const cart = JSON.parse(localStorage.getItem("cart"))
    if (!cart) {
      return
    }

    let total = 0
    for (let i=0; i < cart.length; i++) {
      const item = cart[i]
      total += item.price * item.quantity
      const div = document.createElement("div")
      div.classList.add("mt-2")
      div.innerText = `Item: ${item.name} - Price: R$${item.price/100.0} - Size: ${item.size} - Quantity: ${item.quantity}`
      const deleteButton = document.createElement("button")
      deleteButton.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" class="inline w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6M1 7h22M8 7V5a2 2 0 012-2h2a2 2 0 012 2v2" /></svg>`
      console.log("item.id: ", item.id)
      deleteButton.value = JSON.stringify({id: item.id, size: item.size})
      deleteButton.classList.add("bg-red-500", "rounded", "text-white", "px-2", "py-1", "ml-2", "hover:bg-red-600", "transition", "duration-200")
      deleteButton.addEventListener("click", this.removeFromCart)
      div.appendChild(deleteButton)
      this.element.prepend(div)
    }

    const totalEl = document.createElement("div")
    totalEl.innerText= ` $${total/100.0}`
    let totalContainer = document.getElementById("total")
    totalContainer.appendChild(totalEl)
  }

  clear() {
    localStorage.removeItem("cart")
    window.location.reload()
  }

  removeFromCart(event) {
    const cart = JSON.parse(localStorage.getItem("cart"))
    const values = JSON.parse(event.target.value)
    const {id, size} = values
    const index = cart.findIndex(item => item.id === id && item.size === size)
    if (index >= 0) {
      cart.splice(index, 1)
    }
    localStorage.setItem("cart", JSON.stringify(cart))
    window.location.reload()
  }

  checkout() {
    const cart = JSON.parse(localStorage.getItem("cart"))
    const payload = {
      authenticity_token: "",
      cart: cart
    }

    const csrfToken = document.querySelector("[name='csrf-token']").content

    // Limpar mensagens de erro anteriores
    const errorContainer = document.getElementById("errorContainer")
    errorContainer.innerHTML = ""
    
    console.log("Enviando checkout com:", payload) // DEBUG

    fetch("/checkout", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify(payload)
    }).then(response => {
        console.log("Response status:", response.status) // DEBUG
        console.log("Response ok:", response.ok) // DEBUG
        
        if (response.ok) {
          response.json().then(body => {
            console.log("Success body:", body) // DEBUG
            window.location.href = body.url
          })
        } else {
          console.log("Error occurred, parsing response...") // DEBUG
          response.text().then(text => {
            console.log("Error response text:", text) // DEBUG
            try {
              const body = JSON.parse(text)
              console.log("Error body:", body) // DEBUG
              
              const errorEl = document.createElement("div")
              errorEl.classList.add("bg-red-100", "border", "border-red-400", "text-red-700", "px-4", "py-3", "rounded", "mb-4")
              errorEl.innerHTML = `
                <strong class="font-bold">Erro!</strong>
                <span class="block sm:inline">${body.error || 'Houve um erro ao processar seu pedido.'}</span>
              `
              errorContainer.appendChild(errorEl)
              console.log("Error element added to container") // DEBUG
            } catch (e) {
              console.log("Failed to parse JSON:", e) // DEBUG
              const errorEl = document.createElement("div")
              errorEl.classList.add("bg-red-100", "border", "border-red-400", "text-red-700", "px-4", "py-3", "rounded", "mb-4")
              errorEl.innerHTML = `
                <strong class="font-bold">Erro!</strong>
                <span class="block sm:inline">Houve um erro ao processar seu pedido.</span>
              `
              errorContainer.appendChild(errorEl)
            }
          })
        }
      }).catch(error => {
        console.log("Fetch error:", error) // DEBUG
      })
  }

}