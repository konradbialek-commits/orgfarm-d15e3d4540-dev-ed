import { LightningElement, track } from 'lwc';
import IMAGE_ZERO from '@salesforce/resourceUrl/image_0';
import IMAGE_ONE from '@salesforce/resourceUrl/image_1';
import IMAGE_TWO from '@salesforce/resourceUrl/image_2';

export default class BookSmartSalesCarousel extends LightningElement {
    @track currentSlideIndex = 0;
    slideInterval;

    @track slides = [
        {
            id: 'slide1',
            image: IMAGE_ZERO,
            header: 'SALES SUPERSTAR!',
            description: 'Sarah J. closed the most opportunities this month. Congratulations!'
        },
        {
            id: 'slide2',
            image: IMAGE_ONE,
            header: 'BIG WIN! SECURE YOUR ACCOUNTS',
            description: 'Our new Premium Corporate Subscription has launched. Focus on key accounts.'
        },
        {
            id: 'slide3',
            image: IMAGE_TWO,
            header: 'SUMMER READING CHALLENGE IS ON!',
            description: 'Go all in to reach 120% of your Q2 targets by August 31st.'
        }
    ];

    connectedCallback() {
        this.updateSlideClasses();
        this.startTimer();
    }

    disconnectedCallback() {
        clearInterval(this.slideInterval);
    }

    startTimer() {
        this.slideInterval = setInterval(() => {
            this.nextSlide();
        }, 6000);
    }

    nextSlide() {
        this.currentSlideIndex = (this.currentSlideIndex + 1) % this.slides.length;
        this.updateSlideClasses();
    }

    handlePrevClick() {
        clearInterval(this.slideInterval);
        this.currentSlideIndex = (this.currentSlideIndex - 1 + this.slides.length) % this.slides.length;
        this.updateSlideClasses();
        this.startTimer();
    }

    handleNextClick() {
        clearInterval(this.slideInterval);
        this.nextSlide();
        this.startTimer();
    }

    handleDotClick(event) {
        clearInterval(this.slideInterval);
        this.currentSlideIndex = parseInt(event.target.dataset.index, 10);
        this.updateSlideClasses();
        this.startTimer(); 
    }

    updateSlideClasses() {
        this.slides = this.slides.map((slide, index) => {
            return {
                ...slide,
                cssClass: index === this.currentSlideIndex ? 'slide active' : 'slide'
            };
        });
    }

    get dots() {
        return this.slides.map((slide, index) => {
            return {
                index: index,
                cssClass: index === this.currentSlideIndex ? 'dot active-dot' : 'dot'
            };
        });
    }
}