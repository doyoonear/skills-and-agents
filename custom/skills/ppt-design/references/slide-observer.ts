import { useEffect, RefObject } from 'react';

interface UseSlideObserverProps {
  slideRefs: RefObject<HTMLDivElement | null>[];
  setCurrentSlide: (slide: number) => void;
}

export function useSlideObserver({
  slideRefs,
  setCurrentSlide,
}: UseSlideObserverProps) {
  useEffect(() => {
    const observerOptions = {
      root: null,
      rootMargin: '0px',
      threshold: 0.5,
    };

    const observerCallback: IntersectionObserverCallback = (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          const slideIndex = slideRefs.findIndex(
            (ref) => ref.current === entry.target
          );
          if (slideIndex !== -1) {
            setCurrentSlide(slideIndex);
          }
        }
      });
    };

    const observer = new IntersectionObserver(
      observerCallback,
      observerOptions
    );

    slideRefs.forEach((ref) => {
      if (ref.current) {
        observer.observe(ref.current);
      }
    });

    return () => {
      slideRefs.forEach((ref) => {
        if (ref.current) {
          observer.unobserve(ref.current);
        }
      });
    };
  }, [slideRefs, setCurrentSlide]);
}
