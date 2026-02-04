import { ReactNode, forwardRef } from 'react';

interface SlideProps {
  children: ReactNode;
  className?: string;
}

export const Slide = forwardRef<HTMLDivElement, SlideProps>(
  ({ children, className = '' }, ref) => {
    return (
      <div
        ref={ref}
        className={`
          min-h-screen w-full
          flex items-center justify-center
          snap-start snap-always
          ${className}
        `}
      >
        <div className="w-full max-w-7xl px-8 py-16">
          {children}
        </div>
      </div>
    );
  }
);

Slide.displayName = 'Slide';
