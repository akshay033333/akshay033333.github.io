// Mobile Navigation Toggle
const hamburger = document.querySelector('.hamburger');
const navMenu = document.querySelector('.nav-menu');

hamburger.addEventListener('click', () => {
    hamburger.classList.toggle('active');
    navMenu.classList.toggle('active');
});

// Close mobile menu when clicking on a link
document.querySelectorAll('.nav-link').forEach(n => n.addEventListener('click', () => {
    hamburger.classList.remove('active');
    navMenu.classList.remove('active');
}));

// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Navbar shadow change on scroll (respect theme CSS variables)
window.addEventListener('scroll', () => {
    const navbar = document.querySelector('.navbar');
    if (!navbar) return;
    if (window.scrollY > 100) {
        navbar.style.boxShadow = '0 2px 20px rgba(0, 0, 0, 0.15)';
    } else {
        navbar.style.boxShadow = 'none';
    }
});

// Intersection Observer for animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Observe elements for animation
document.addEventListener('DOMContentLoaded', () => {
    const animatedElements = document.querySelectorAll('.project-card, .skill-category, .about-stats .stat');
    
    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
});

// Add typing effect to hero title
function typeWriter(element, text, speed = 100) {
    let i = 0;
    element.innerHTML = '';
    
    function type() {
        if (i < text.length) {
            element.innerHTML += text.charAt(i);
            i++;
            setTimeout(type, speed);
        }
    }
    
    type();
}

// Initialize typing effect when page loads
document.addEventListener('DOMContentLoaded', () => {
    const heroTitle = document.querySelector('.hero-title');
    if (heroTitle) {
        const originalText = heroTitle.innerHTML;
        typeWriter(heroTitle, originalText, 50);
    }
});

// Form validation for contact form (if you add one later)
function validateForm(form) {
    const inputs = form.querySelectorAll('input[required], textarea[required]');
    let isValid = true;
    
    inputs.forEach(input => {
        if (!input.value.trim()) {
            input.style.borderColor = '#ef4444';
            isValid = false;
        } else {
            input.style.borderColor = '#d1d5db';
        }
    });
    
    return isValid;
}

// Add loading animation for buttons
document.querySelectorAll('.btn').forEach(button => {
    button.addEventListener('click', function(e) {
        if (this.classList.contains('btn-primary') || this.classList.contains('btn-secondary')) {
            this.style.transform = 'scale(0.95)';
            setTimeout(() => {
                this.style.transform = 'scale(1)';
            }, 150);
        }
    });
});

// Parallax effect for hero section
window.addEventListener('scroll', () => {
    const scrolled = window.pageYOffset;
    const hero = document.querySelector('.hero');
    if (hero) {
        const rate = scrolled * -0.5;
        hero.style.transform = `translateY(${rate}px)`;
    }
});

// Add active state to navigation based on scroll position
window.addEventListener('scroll', () => {
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.nav-link');
    
    let current = '';
    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        const sectionHeight = section.clientHeight;
        if (window.pageYOffset >= sectionTop - 200) {
            current = section.getAttribute('id');
        }
    });
    
    navLinks.forEach(link => {
        link.classList.remove('active');
        if (link.getAttribute('href') === `#${current}`) {
            link.classList.add('active');
        }
    });
});

// Profile photo error handling
document.addEventListener('DOMContentLoaded', () => {
    const profilePhoto = document.getElementById('profile-photo');
    const profileFallback = document.getElementById('profile-fallback');
    
    if (profilePhoto && profileFallback) {
        profilePhoto.addEventListener('error', () => {
            profilePhoto.style.display = 'none';
            profileFallback.style.display = 'flex';
        });
    }
});

// Theme Toggle Functionality
let currentTheme = localStorage.getItem('theme') || 'light';
document.documentElement.setAttribute('data-theme', currentTheme);

function toggleTheme() {
    currentTheme = currentTheme === 'light' ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', currentTheme);
    localStorage.setItem('theme', currentTheme);
    
    // Update theme button icon
    const themeBtn = document.querySelector('.theme-btn i');
    if (themeBtn) {
        themeBtn.className = currentTheme === 'light' ? 'fas fa-moon' : 'fas fa-sun';
    }
}

// Initialize theme button
document.addEventListener('DOMContentLoaded', function() {
    const themeBtn = document.querySelector('.theme-btn');
    if (themeBtn) {
        themeBtn.addEventListener('click', toggleTheme);
        
        // Set initial icon
        const themeIcon = themeBtn.querySelector('i');
        if (themeIcon) {
            themeIcon.className = currentTheme === 'light' ? 'fas fa-moon' : 'fas fa-sun';
        }
    }
});

// Back to Top Button
document.addEventListener('DOMContentLoaded', function() {
    const backToTopBtn = document.getElementById('back-to-top');
    
    if (backToTopBtn) {
        // Show/hide button based on scroll position
        window.addEventListener('scroll', () => {
            if (window.scrollY > 300) {
                backToTopBtn.style.display = 'flex';
            } else {
                backToTopBtn.style.display = 'none';
            }
        });
        
        // Smooth scroll to top when clicked
        backToTopBtn.addEventListener('click', () => {
            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        });
    }
});

// Add CSS for active navigation state
const style = document.createElement('style');
style.textContent = `
    .nav-link.active {
        color: #2563eb !important;
    }
    .nav-link.active::after {
        width: 100% !important;
    }
`;
document.head.appendChild(style); 

// Visitor Analytics and Tracking
document.addEventListener('DOMContentLoaded', function() {
    // Track page views
    trackPageView();
    
    // Track user engagement
    trackUserEngagement();
    
    // Track project clicks
    trackProjectClicks();
});

function trackPageView() {
    // Increment page view counter
    let pageViews = localStorage.getItem('pageViews') || 0;
    pageViews = parseInt(pageViews) + 1;
    localStorage.setItem('pageViews', pageViews);
    
    // Display visitor count (optional)
    displayVisitorCount(pageViews);
    
    // Send to analytics if available
    if (typeof gtag !== 'undefined') {
        gtag('event', 'page_view', {
            page_title: document.title,
            page_location: window.location.href
        });
    }
}

function displayVisitorCount(count) {
    // Create visitor counter element
    const visitorCounter = document.createElement('div');
    visitorCounter.className = 'visitor-counter';
    visitorCounter.innerHTML = `
        <span class="counter-icon">👥</span>
        <span class="counter-text">Visitors: ${count}</span>
    `;
    
    // Add to footer
    const footer = document.querySelector('footer');
    if (footer) {
        footer.appendChild(visitorCounter);
    }
}

function trackUserEngagement() {
    // Track scroll depth
    let maxScroll = 0;
    window.addEventListener('scroll', () => {
        const scrollPercent = Math.round((window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100);
        if (scrollPercent > maxScroll) {
            maxScroll = scrollPercent;
            
            // Track scroll milestones
            if (maxScroll >= 25 && maxScroll < 50) {
                trackEvent('scroll_25_percent');
            } else if (maxScroll >= 50 && maxScroll < 75) {
                trackEvent('scroll_50_percent');
            } else if (maxScroll >= 75) {
                trackEvent('scroll_75_percent');
            }
        }
    });
    
    // Track time on page
    let startTime = Date.now();
    window.addEventListener('beforeunload', () => {
        const timeOnPage = Math.round((Date.now() - startTime) / 1000);
        trackEvent('time_on_page', { value: timeOnPage });
    });
}

function trackProjectClicks() {
    const projectLinks = document.querySelectorAll('.project-link');
    projectLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            const projectName = e.target.closest('.project-card').querySelector('h3').textContent;
            trackEvent('project_click', {
                project_name: projectName,
                link_url: e.target.href
            });
        });
    });
}

function trackEvent(eventName, parameters = {}) {
    // Send to Google Analytics if available
    if (typeof gtag !== 'undefined') {
        gtag('event', eventName, parameters);
    }
    
    // Log locally for debugging
    console.log('Event tracked:', eventName, parameters);
} 

// Enhanced Resume Download Tracking
document.addEventListener('DOMContentLoaded', function() {
    // Track resume downloads
    trackResumeDownloads();
    
    // Track user engagement
    trackUserEngagement();
    
    // Track project clicks
    trackProjectClicks();
});

function trackResumeDownloads() {
    const resumeButtons = document.querySelectorAll('a[href*="resume.pdf"], a[href*="resume.pdf"]');
    
    resumeButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault(); // Prevent default to handle manually
            
            // Track the download event
            trackEvent('resume_download', {
                format: 'pdf',
                button_text: this.textContent.trim(),
                button_location: this.closest('section')?.id || 'unknown'
            });
            
            // Log for debugging
            console.log('Resume download initiated:', this.href);
            
            // Try to download the resume
            downloadResume(this.href);
        });
    });
}

function downloadResume(url) {
    const button = document.querySelector('a[href*="resume.pdf"]');
    const originalText = button.innerHTML;
    
    // Show downloading state
    button.classList.add('downloading');
    button.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Downloading...';
    
    // Method 1: Try fetch with blob download
    fetch(url)
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return response.blob();
        })
        .then(blob => {
            // Create download link
            const downloadUrl = window.URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = downloadUrl;
            link.download = 'Akshay_Kailasa_Resume.pdf';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            window.URL.revokeObjectURL(downloadUrl);
            
            // Show success state
            button.classList.remove('downloading');
            button.classList.add('download-success');
            button.innerHTML = '<i class="fas fa-check"></i> Downloaded!';
            
            console.log('✅ Resume downloaded successfully via blob method');
            trackEvent('resume_download_success', { method: 'blob', size: blob.size });
            
            // Reset button after 3 seconds
            setTimeout(() => {
                button.classList.remove('download-success');
                button.innerHTML = originalText;
            }, 3000);
        })
        .catch(error => {
            console.error('❌ Blob download failed:', error);
            trackEvent('resume_download_error', { method: 'blob', error: error.message });
            
            // Method 2: Fallback to direct link
            console.log('🔄 Trying fallback download method...');
            const fallbackLink = document.createElement('a');
            fallbackLink.href = url;
            fallbackLink.download = 'Akshay_Kailasa_Resume.pdf';
            fallbackLink.target = '_blank';
            fallbackLink.rel = 'noopener noreferrer';
            document.body.appendChild(fallbackLink);
            fallbackLink.click();
            document.body.removeChild(fallbackLink);
            
            // Show fallback state
            button.classList.remove('downloading');
            button.innerHTML = '<i class="fas fa-external-link-alt"></i> Opening...';
            
            trackEvent('resume_download_fallback', { method: 'direct_link' });
            
            // Reset button after 3 seconds
            setTimeout(() => {
                button.innerHTML = originalText;
            }, 3000);
        });
} 

// Navbar Scroll Effect and Active State Management
document.addEventListener('DOMContentLoaded', function() {
    // Navbar scroll effect
    handleNavbarScroll();
    
    // Active navigation link management
    handleActiveNavigation();
});

function handleNavbarScroll() {
    const navbar = document.querySelector('.navbar');
    
    window.addEventListener('scroll', () => {
        if (window.scrollY > 50) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }
    });
}

function handleActiveNavigation() {
    const navLinks = document.querySelectorAll('.nav-link');
    const sections = document.querySelectorAll('section[id]');
    
    function updateActiveLink() {
        const scrollPos = window.scrollY + 100;
        
        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.offsetHeight;
            const sectionId = section.getAttribute('id');
            
            if (scrollPos >= sectionTop && scrollPos < sectionTop + sectionHeight) {
                navLinks.forEach(link => {
                    link.classList.remove('active');
                    if (link.getAttribute('href') === `#${sectionId}`) {
                        link.classList.add('active');
                    }
                });
            }
        });
    }
    
    window.addEventListener('scroll', updateActiveLink);
    updateActiveLink(); // Initial call
} 

// Certification Badge Interactions
document.addEventListener('DOMContentLoaded', function() {
    // Add click functionality to certification badges
    const certBadges = document.querySelectorAll('.cert-badge');
    
    certBadges.forEach(badge => {
        badge.addEventListener('click', function() {
            // Add click animation
            this.style.transform = 'scale(0.95)';
            setTimeout(() => {
                this.style.transform = 'translateY(-2px)';
            }, 150);
            
            // Track certification badge clicks
            const certType = this.classList.contains('databricks') ? 'Databricks' : 'AWS';
            trackEvent('certification_badge_click', { 
                certification_type: certType,
                location: 'hero_section'
            });
        });
        
        // Add hover sound effect (optional)
        badge.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-2px) scale(1.02)';
        });
        
        badge.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0) scale(1)';
        });
    });
    
    // Enhanced certification item interactions
    const certItems = document.querySelectorAll('.cert-item');
    
    certItems.forEach((item, index) => {
        // Add staggered animation delay
        item.style.animationDelay = `${index * 0.1}s`;
        
        // Add click tracking for verification links
        const verifyLink = item.querySelector('.cert-verify-link');
        if (verifyLink) {
            verifyLink.addEventListener('click', function() {
                const certTitle = item.querySelector('.cert-title').textContent;
                trackEvent('certification_verification_click', {
                    certification: certTitle,
                    location: 'about_section'
                });
            });
        }
    });
}); 