// GroupBuy E-commerce - Main JavaScript File

document.addEventListener('DOMContentLoaded', function() {
    // Initialize tooltips
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Initialize popovers
    var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
    var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl);
    });

    // Update cart count
    updateCartCount();

    // Product quantity selector
    initQuantityControls();

    // Add to cart functionality
    setupAddToCartForms();

    // Product image gallery
    setupProductGallery();

    // MOQ Progress refresh
    refreshMOQProgress();
});

/**
 * Initialize quantity input controls
 */
function initQuantityControls() {
    // Get all quantity controls on page
    const quantityInputs = document.querySelectorAll('.quantity-input');
    
    if(quantityInputs.length === 0) return;

    quantityInputs.forEach(input => {
        const decreaseBtn = input.parentElement.querySelector('[data-action="decrease"]');
        const increaseBtn = input.parentElement.querySelector('[data-action="increase"]');

        if(decreaseBtn) {
            decreaseBtn.addEventListener('click', function() {
                let currentValue = parseInt(input.value);
                if(currentValue > 1) {
                    input.value = currentValue - 1;
                    input.dispatchEvent(new Event('change'));
                }
            });
        }

        if(increaseBtn) {
            increaseBtn.addEventListener('click', function() {
                let currentValue = parseInt(input.value);
                let max = input.getAttribute('max');
                
                if(!max || currentValue < parseInt(max)) {
                    input.value = currentValue + 1;
                    input.dispatchEvent(new Event('change'));
                }
            });
        }

        // Validate input when user types
        input.addEventListener('input', function() {
            let min = parseInt(input.getAttribute('min') || 1);
            let max = parseInt(input.getAttribute('max') || 9999);
            let value = parseInt(input.value);

            if(isNaN(value) || value < min) {
                input.value = min;
            } else if(max && value > max) {
                input.value = max;
            }
        });
    });
}

/**
 * Setup add to cart forms with AJAX
 */
function setupAddToCartForms() {
    const addToCartForms = document.querySelectorAll('.add-to-cart-form');
    
    if(addToCartForms.length === 0) return;

    addToCartForms.forEach(form => {
        form.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const formData = new FormData(form);
            
            fetch(form.action, {
                method: 'POST',
                body: formData,
                headers: {
                    'X-Requested-With': 'XMLHttpRequest'
                }
            })
            .then(response => response.json())
            .then(data => {
                if(data.status === 'success') {
                    // Update cart count
                    updateCartCount(data.cart_total);
                    
                    // Show success message
                    showToast('Success', data.message, 'success');
                } else {
                    showToast('Error', data.message, 'error');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                showToast('Error', 'An error occurred. Please try again.', 'error');
            });
        });
    });
}

/**
 * Setup product image gallery
 */
function setupProductGallery() {
    const thumbnails = document.querySelectorAll('.thumbnail');
    const mainImage = document.querySelector('.main-image-container img');
    
    if(thumbnails.length === 0 || !mainImage) return;

    thumbnails.forEach(thumbnail => {
        thumbnail.addEventListener('click', function() {
            const newSrc = this.getAttribute('src');
            const newAlt = this.getAttribute('alt');
            
            mainImage.setAttribute('src', newSrc);
            if(newAlt) {
                mainImage.setAttribute('alt', newAlt);
            }

            // Update active state
            thumbnails.forEach(t => t.classList.remove('border-primary'));
            this.classList.add('border-primary');
        });
    });
}

/**
 * Update cart count in navigation
 */
function updateCartCount(count) {
    const cartCountElements = document.querySelectorAll('.cart-count');
    
    if(cartCountElements.length === 0) return;

    if(count !== undefined) {
        cartCountElements.forEach(element => {
            element.textContent = count;
        });
    } else {
        // Try to get the current cart count from the server
        fetch('/api/cart/')
            .then(response => {
                if(!response.ok) {
                    throw new Error('Network response was not ok');
                }
                return response.json();
            })
            .then(data => {
                if(data.total_items !== undefined) {
                    cartCountElements.forEach(element => {
                        element.textContent = data.total_items;
                    });
                }
            })
            .catch(error => {
                console.error('Error fetching cart count:', error);
            });
    }
}

/**
 * Refresh MOQ progress on product pages
 */
function refreshMOQProgress() {
    const batchElement = document.getElementById('active-batch');
    
    if(!batchElement) return;

    const batchId = batchElement.getAttribute('data-batch-id');
    
    if(!batchId) return;

    // Set up periodic refresh
    setInterval(() => {
        fetch(`/products/batch-status/${batchId}/`, {
            headers: {
                'X-Requested-With': 'XMLHttpRequest'
            }
        })
        .then(response => response.json())
        .then(data => {
            // Update progress bar
            const progressBar = document.querySelector('.progress-bar');
            if(progressBar) {
                progressBar.style.width = `${data.progress_percentage}%`;
                progressBar.setAttribute('aria-valuenow', data.progress_percentage);
                progressBar.textContent = `${data.progress_percentage}%`;
            }

            // Update current and remaining quantities
            const currentQuantityEl = document.getElementById('current-quantity');
            const remainingQuantityEl = document.getElementById('remaining-quantity');
            
            if(currentQuantityEl) {
                currentQuantityEl.textContent = data.current_quantity;
            }
            
            if(remainingQuantityEl) {
                remainingQuantityEl.textContent = data.remaining_quantity;
            }

            // If MOQ is reached, show alert
            if(data.is_fulfilled) {
                const moqAlert = document.getElementById('moq-reached-alert');
                if(moqAlert && moqAlert.classList.contains('d-none')) {
                    moqAlert.classList.remove('d-none');
                    
                    // Hide join waitlist button
                    const joinButton = document.getElementById('join-waitlist-btn');
                    if(joinButton) {
                        joinButton.classList.add('d-none');
                    }
                }
            }
        })
        .catch(error => {
            console.error('Error refreshing batch status:', error);
        });
    }, 30000); // Refresh every 30 seconds
}

/**
 * Show toast notification
 */
function showToast(title, message, type = 'info') {
    // Create toast container if it doesn't exist
    let toastContainer = document.querySelector('.toast-container');
    if (!toastContainer) {
        toastContainer = document.createElement('div');
        toastContainer.className = 'toast-container';
        document.body.appendChild(toastContainer);
    }

    // Create toast element
    const toastEl = document.createElement('div');
    toastEl.className = `toast align-items-center ${type === 'error' ? 'bg-danger' : type === 'success' ? 'bg-success' : 'bg-primary'} text-white border-0`;
    toastEl.setAttribute('role', 'alert');
    toastEl.setAttribute('aria-live', 'assertive');
    toastEl.setAttribute('aria-atomic', 'true');
    
    // Toast content
    const toastContent = `
        <div class="d-flex">
            <div class="toast-body">
                <strong>${title}:</strong> ${message}
            </div>
            <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
        </div>
    `;
    toastEl.innerHTML = toastContent;
    
    // Add to container
    toastContainer.appendChild(toastEl);
    
    // Initialize Bootstrap toast
    const toast = new bootstrap.Toast(toastEl, {
        animation: true,
        autohide: true,
        delay: 5000
    });
    
    // Show toast
    toast.show();
    
    // Remove from DOM after hidden
    toastEl.addEventListener('hidden.bs.toast', function() {
        toastEl.remove();
    });
}

/**
 * Format currency
 */
function formatCurrency(amount) {
    return '$' + parseFloat(amount).toFixed(2);
}

/**
 * Handle form validation
 */
function validateForm(form) {
    const inputs = form.querySelectorAll('input, select, textarea');
    let isValid = true;
    
    inputs.forEach(input => {
        if (input.hasAttribute('required') && !input.value.trim()) {
            input.classList.add('is-invalid');
            isValid = false;
        } else {
            input.classList.remove('is-invalid');
            
            // Validate email fields
            if (input.type === 'email' && input.value) {
                const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                if (!emailPattern.test(input.value)) {
                    input.classList.add('is-invalid');
                    isValid = false;
                }
            }
            
            // Validate password fields
            if (input.type === 'password' && input.value && input.value.length < 8) {
                input.classList.add('is-invalid');
                isValid = false;
            }
        }
    });
    
    return isValid;
}
