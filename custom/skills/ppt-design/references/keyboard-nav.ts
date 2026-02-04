import { useEffect, RefObject } from 'react';

interface UseKeyboardNavigationProps {
  slideRefs: RefObject<HTMLDivElement | null>[];
  currentSlide: number;
  setCurrentSlide: (slide: number) => void;
  totalSlides: number;
}

export function useKeyboardNavigation({
  slideRefs,
  currentSlide,
  setCurrentSlide,
  totalSlides,
}: UseKeyboardNavigationProps) {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'ArrowDown' || e.key === 'ArrowRight') {
        e.preventDefault();
        if (currentSlide < totalSlides - 1) {
          const nextSlide = currentSlide + 1;
          setCurrentSlide(nextSlide);
          slideRefs[nextSlide]?.current?.scrollIntoView({
            behavior: 'auto',
            block: 'start',
          });
        }
      } else if (e.key === 'ArrowUp' || e.key === 'ArrowLeft') {
        e.preventDefault();
        if (currentSlide > 0) {
          const prevSlide = currentSlide - 1;
          setCurrentSlide(prevSlide);
          slideRefs[prevSlide]?.current?.scrollIntoView({
            behavior: 'auto',
            block: 'start',
          });
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [currentSlide, slideRefs, setCurrentSlide, totalSlides]);
}
