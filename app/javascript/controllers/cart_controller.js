import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="cart"
export default class extends Controller {
  initialize() {
    this.freteValor = 0 // Armazenar valor do frete

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

    this.updateTotals(total)
  }

  updateTotals(subtotal) {
    const subtotalEl = document.getElementById("subtotal")
    const totalEl = document.getElementById("total")
    
    subtotalEl.innerText = `R$ ${(subtotal/100.0).toFixed(2)}`
    
    const totalFinal = subtotal + this.freteValor
    totalEl.innerText = `R$ ${(totalFinal/100.0).toFixed(2)}`
  }

  formatCep(event) {
    let value = event.target.value.replace(/\D/g, '')
    if (value.length > 5) {
      value = value.replace(/^(\d{5})(\d)/, '$1-$2')
    }
    event.target.value = value
    
    // Adicionar feedback visual
    const input = event.target
    if (value.length === 8) {
      input.classList.remove("border-red-500")
      input.classList.add("border-green-500")
    } else {
      input.classList.remove("border-green-500", "border-red-500")
    }
  }

  calcularFrete(event) {
    const cep = event.target.value.replace(/\D/g, '')
    
    if (cep.length !== 8) {
      this.hideFreteInfo()
      event.target.classList.remove("border-green-500")
      return
    }

    this.showFreteLoading()
    
    fetch(`/checkouts/calcular_frete?cep_destino=${cep}`)
      .then(response => {
        if (!response.ok) {
          throw new Error('Erro ao calcular frete')
        }
        return response.json()
      })
      .then(data => {
        this.hideFreteLoading()
        const freteValorFloat = parseFloat(data.valor.replace(",", "."))
        this.freteValor = Math.round(freteValorFloat * 100)
        
        const freteContainer = document.getElementById("frete-container")
        const freteValorEl = document.getElementById("frete-valor")
        
        // Mostrar valor e informação adicional se houver erro
        let freteText = `R$ ${freteValorFloat.toFixed(2)}`
        if (!data.sucesso && data.erro) {
          freteText += ` *`
          this.showFreteError(data.erro)
        } else {
          this.hideFreteError()
        }
        
        freteValorEl.innerText = freteText
        freteContainer.style.display = "flex"
        
        // Atualizar total
        const cart = JSON.parse(localStorage.getItem("cart")) || []
        let subtotal = 0
        cart.forEach(item => {
          subtotal += item.price * item.quantity
        })
        this.updateTotals(subtotal)
        
        this.hideFreteError()
      })
      .catch(error => {
        this.hideFreteLoading()
        this.showFreteError("Erro ao calcular frete. Verifique o CEP.")
        this.hideFreteInfo()
      })
  }

  showFreteLoading() {
    document.getElementById("frete-loading").classList.remove("hidden")
  }

  hideFreteLoading() {
    document.getElementById("frete-loading").classList.add("hidden")
  }

  showFreteError(message) {
    const errorEl = document.getElementById("frete-error")
    errorEl.innerText = message
    errorEl.classList.remove("hidden")
  }

  hideFreteError() {
    document.getElementById("frete-error").classList.add("hidden")
  }

  hideFreteInfo() {
    document.getElementById("frete-container").style.display = "none"
    this.freteValor = 0
    
    // Atualizar total sem frete
    const cart = JSON.parse(localStorage.getItem("cart")) || []
    let subtotal = 0
    cart.forEach(item => {
      subtotal += item.price * item.quantity
    })
    this.updateTotals(subtotal)
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
    const cep = document.getElementById("cep_destino").value.replace(/\D/g, '')
    
    // Limpar mensagens de erro anteriores
    const errorContainer = document.getElementById("errorContainer")
    errorContainer.innerHTML = ""
    
    // Validar se o CEP foi preenchido
    if (!cep || cep.length !== 8) {
      const errorEl = document.createElement("div")
      errorEl.classList.add("bg-red-100", "border", "border-red-400", "text-red-700", "px-4", "py-3", "rounded", "mb-4")
      errorEl.innerHTML = `
        <strong class="font-bold">Erro!</strong>
        <span class="block sm:inline">Por favor, digite um CEP válido antes de finalizar a compra.</span>
      `
      errorContainer.appendChild(errorEl)
      
      // Destacar o campo CEP
      const cepInput = document.getElementById("cep_destino")
      cepInput.focus()
      cepInput.classList.add("border-red-500")
      setTimeout(() => {
        cepInput.classList.remove("border-red-500")
      }, 3000)
      
      return
    }
    
    // Validar se o frete foi calculado
    const freteContainer = document.getElementById("frete-container")
    if (freteContainer.style.display === "none" || this.freteValor === 0) {
      const errorEl = document.createElement("div")
      errorEl.classList.add("bg-yellow-100", "border", "border-yellow-400", "text-yellow-700", "px-4", "py-3", "rounded", "mb-4")
      errorEl.innerHTML = `
        <strong class="font-bold">Atenção!</strong>
        <span class="block sm:inline">Aguarde o cálculo do frete ou clique fora do campo CEP para calcular.</span>
      `
      errorContainer.appendChild(errorEl)
      return
    }

    const payload = {
      authenticity_token: "",
      cart: cart,
      cep_destino: cep
    }

    const csrfToken = document.querySelector("[name='csrf-token']").content
    
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