const Config = {
  inventory: "rsg-inventory",
}

let currentBlackmarket = null
let currentMode = "buy"
let selectedItem = null
let items = []
let playerMoney = { bloodmoney: 0, cash: 0 }

// Declare the $ variable
const $ = window.jQuery

// Initialize the interface
$(document).ready(() => {
  initializeEventListeners()
  hideInterface()
})

function initializeEventListeners() {
  // ESC key to close
  $(document).on("keydown", (event) => {
    if (event.keyCode === 27) {
      closeInterface()
    }
  })

  // Close button
  $("#closeBtn").on("click", closeInterface)

  // Tab switching
  $(".tab-btn").on("click", function () {
    const tab = $(this).data("tab")
    switchTab(tab)
  })

  // Modal controls
  $("#modalClose, #cancelBtn").on("click", closeModal)
  $("#confirmBtn").on("click", confirmTransaction)

  // Quantity controls
  $("#decreaseBtn").on("click", () => {
    const input = $("#quantityInput")
    const current = Number.parseInt(input.val()) || 1
    const min = Number.parseInt(input.attr("min")) || 1
    if (current > min) {
      input.val(current - 1)
      updateTotalPrice()
    }
  })

  $("#increaseBtn").on("click", () => {
    const input = $("#quantityInput")
    const current = Number.parseInt(input.val()) || 1
    const max = Number.parseInt(input.attr("max")) || 1
    if (current < max) {
      input.val(current + 1)
      updateTotalPrice()
    }
  })

  $("#quantityInput").on("input change", function () {
    const value = Number.parseInt($(this).val()) || 1
    const min = Number.parseInt($(this).attr("min")) || 1
    const max = Number.parseInt($(this).attr("max")) || 1

    if (value < min) $(this).val(min)
    if (value > max) $(this).val(max)

    updateTotalPrice()
  })

  // Click outside modal to close
  $("#quantityModal").on("click", function (e) {
    if (e.target === this) {
      closeModal()
    }
  })
}

// Message listener for NUI communication
window.addEventListener("message", (event) => {
  const data = event.data

  if (data.type === "blackmarket") {
    openBlackmarket(data)
  } else if (data.type === "updateMoney") {
    playerMoney = data.money
    updateMoneyDisplay()
  }
})

function openBlackmarket(data) {
  currentBlackmarket = data.id

  // Update title if label is provided
  if (data.label) {
    $("#blackmarketTitle").text(data.label)
  }

  // Update player money if provided
  if (data.playerMoney) {
    playerMoney = data.playerMoney
    updateMoneyDisplay()
    console.log("Player Money:", playerMoney) // Debug log
  }

  // Get inventory config
  $.post("https://jc-blackmarket/getInventory", JSON.stringify(), (result) => {
    Config.inventory = result
  }).fail(() => {
    console.log("Failed to get inventory config")
  })

  // Show/hide tabs based on permissions
  if (!data.sells) {
    $("#buyTab").hide()
    if (data.buys) {
      switchTab("sell")
    }
  } else {
    $("#buyTab").show()
  }

  if (!data.buys) {
    $("#sellTab").hide()
    if (data.sells) {
      switchTab("buy")
    }
  } else {
    $("#sellTab").show()
  }

  showInterface()
  loadItems()
}

function updateMoneyDisplay() {
  console.log("Updating money display:", playerMoney) // Debug log
  $("#bloodMoney").text(playerMoney.bloodmoney ? playerMoney.bloodmoney.toLocaleString() : "0")
  $("#cashMoney").text(playerMoney.cash ? playerMoney.cash.toLocaleString() : "0")
}

function refreshPlayerMoney() {
  $.post("https://jc-blackmarket/getPlayerMoney", JSON.stringify(), (money) => {
    playerMoney = money
    updateMoneyDisplay()
    console.log("Refreshed money:", money) // Debug log
  }).fail(() => {
    console.log("Failed to get player money")
  })
}

function showInterface() {
  $("#blackmarket-ui").addClass("active")
}

function hideInterface() {
  $("#blackmarket-ui").removeClass("active")
  closeModal()
}

function closeInterface() {
  hideInterface()

  $.post("https://jc-blackmarket/close", JSON.stringify()).fail(() => {
    console.log("Failed to send close event")
  })
}

function switchTab(tab) {
  currentMode = tab

  // Update tab buttons
  $(".tab-btn").removeClass("active")
  $(`#${tab}Tab`).addClass("active")

  // Update UI mode
  if (tab === "sell") {
    $("#itemsGrid").addClass("sell-mode")
  } else {
    $("#itemsGrid").removeClass("sell-mode")
  }

  loadItems()
}

function loadItems() {
  showLoading()

  const endpoint = currentMode === "buy" ? "getItems" : "getSellableItems"

  $.post(
    `https://jc-blackmarket/${endpoint}`,
    JSON.stringify({
      blackmarket: currentBlackmarket,
    }),
    (data) => {
      items = data || []
      console.log("Loaded items:", items) // Debug log
      renderItems()
    },
  ).fail(() => {
    console.log("Failed to load items")
    hideLoading()
    showEmptyState()
  })
}

function renderItems() {
  hideLoading()
  hideEmptyState()

  const grid = $("#itemsGrid")
  grid.empty()

  if (items.length === 0) {
    showEmptyState()
    return
  }

  items.forEach((item, index) => {
    const itemCard = createItemCard(item, index)
    grid.append(itemCard)
  })
}

function createItemCard(item, index) {
  const imageSrc = getImageSrc(item)
  const stockText = currentMode === "buy" ? `Stock: ${item.amount}` : `You have: ${item.amount}`

  // Create a simple placeholder SVG for missing images
  const placeholderSVG =
    "data:image/svg+xml;base64," +
    btoa(`
    <svg width="80" height="80" viewBox="0 0 80 80" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect width="80" height="80" fill="#444"/>
      <rect x="20" y="20" width="40" height="40" fill="#666"/>
      <text x="40" y="45" text-anchor="middle" fill="#999" font-size="8">No Image</text>
    </svg>
  `)

  const card = $(`
        <div class="item-card" data-index="${index}">
            <img class="item-image" src="${imageSrc}" alt="${item.label}" onerror="this.src='${placeholderSVG}'">
            <div class="item-name">${item.label}</div>
            <div class="item-price">$${item.price.toLocaleString()}</div>
            <div class="item-stock">${stockText}</div>
        </div>
    `)

  // Add event listeners
  card.on("click", () => {
    if (item.amount > 0) {
      openQuantityModal(item)
    }
  })

  card.on("mouseenter", (e) => {
    showTooltip(e, `${item.label} - $${item.price.toLocaleString()}`)
  })

  card.on("mouseleave", () => {
    hideTooltip()
  })

  card.on("mousemove", (e) => {
    updateTooltipPosition(e)
  })

  // Disable card if no stock
  if (item.amount <= 0) {
    card.addClass("disabled").css("opacity", "0.5")
  }

  return card
}

function getImageSrc(item) {
  const imageName = item.image || item.name
  return `nui://${Config.inventory}/html/images/${imageName}.png`
}

function openQuantityModal(item) {
  selectedItem = item

  // Update modal content
  $("#modalTitle").text(`${currentMode === "buy" ? "Buy" : "Sell"} ${item.label}`)
  $("#modalItemImage").attr("src", getImageSrc(item))
  $("#modalItemName").text(item.label)
  $("#modalItemPrice").text(`Price: $${item.price.toLocaleString()} each`)
  $("#modalItemStock").text(`${currentMode === "buy" ? "Available" : "You have"}: ${item.amount}`)

  // Set quantity input constraints
  const minQuantity = 1
  const maxQuantity = Math.max(1, item.amount)

  $("#quantityInput").attr("min", minQuantity).attr("max", maxQuantity).val(minQuantity)

  // Update button styling and check affordability
  const confirmBtn = $("#confirmBtn")
  if (currentMode === "sell") {
    confirmBtn.addClass("sell-mode").removeClass("disabled").prop("disabled", false).text("Confirm")
  } else {
    confirmBtn.removeClass("sell-mode")

    // Check if player can afford at least 1 item
    if (playerMoney.bloodmoney < item.price) {
      confirmBtn.addClass("disabled").prop("disabled", true).text("Can't Afford")
    } else {
      confirmBtn.removeClass("disabled").prop("disabled", false).text("Confirm")
    }
  }

  updateTotalPrice()
  $("#quantityModal").addClass("active")
}

function closeModal() {
  $("#quantityModal").removeClass("active")
  selectedItem = null
}

function updateTotalPrice() {
  if (!selectedItem) return

  const quantity = Number.parseInt($("#quantityInput").val()) || 0
  const total = selectedItem.price * quantity
  $("#totalPrice").text(total.toLocaleString())

  // Update confirm button state for buy mode
  if (currentMode === "buy") {
    const confirmBtn = $("#confirmBtn")
    if (playerMoney.bloodmoney < total) {
      confirmBtn.addClass("disabled").prop("disabled", true).text("Can't Afford")
    } else {
      confirmBtn.removeClass("disabled").prop("disabled", false).text("Confirm")
    }
  }
}

function confirmTransaction() {
  if (!selectedItem || !currentBlackmarket) return

  const quantity = Number.parseInt($("#quantityInput").val()) || 0
  if (quantity <= 0 || quantity > selectedItem.amount) return

  const endpoint = currentMode === "buy" ? "buyItem" : "sellItem"

  $.post(
    `https://jc-blackmarket/${endpoint}`,
    JSON.stringify({
      blackmarket: currentBlackmarket,
      item: selectedItem.name,
      amount: quantity,
      price: selectedItem.price,
    }),
    () => {
      closeModal()

      // Refresh items after transaction
      setTimeout(() => {
        loadItems()
      }, 500)
    },
  ).fail(() => {
    console.log("Transaction failed")
  })
}

function showLoading() {
  $("#loading").addClass("active")
  $("#emptyState").removeClass("active")
  $("#itemsGrid").hide()
}

function hideLoading() {
  $("#loading").removeClass("active")
  $("#itemsGrid").show()
}

function showEmptyState() {
  $("#emptyState").addClass("active")
  $("#itemsGrid").hide()
}

function hideEmptyState() {
  $("#emptyState").removeClass("active")
  $("#itemsGrid").show()
}

function showTooltip(event, text) {
  const tooltip = $("#tooltip")
  tooltip.text(text).addClass("active")
  updateTooltipPosition(event)
}

function updateTooltipPosition(event) {
  const tooltip = $("#tooltip")
  tooltip.css({
    left: event.pageX + 10 + "px",
    top: event.pageY + 10 + "px",
  })
}

function hideTooltip() {
  $("#tooltip").removeClass("active")
}
