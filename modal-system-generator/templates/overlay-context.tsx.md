# Overlay Context 템플릿

메인 Provider + Context + overlay 객체를 구현하는 파일입니다.

## Emotion 버전

```tsx
import {
  createContext,
  useContext,
  useState,
  useCallback,
  ReactNode,
} from 'react';
import { createPortal } from 'react-dom';
import { Backdrop } from './Backdrop';

// ============ Types ============
type OverlayElement = {
  id: string;
  element: ReactNode;
};

type OverlayContextType = {
  open: <T>(
    render: (props: { close: (result?: T) => void; isOpen: boolean }) => ReactNode
  ) => Promise<T | undefined>;
  close: (id: string) => void;
  closeAll: () => void;
};

// ============ Context ============
const OverlayContext = createContext<OverlayContextType | null>(null);

// 전역 함수 저장 (Provider 외부에서 사용)
let globalOpen: OverlayContextType['open'];
let globalClose: OverlayContextType['close'];
let globalCloseAll: OverlayContextType['closeAll'];

// ============ Provider ============
interface OverlayProviderProps {
  children: ReactNode;
}

export function OverlayProvider({ children }: OverlayProviderProps) {
  const [overlays, setOverlays] = useState<OverlayElement[]>([]);
  const [resolvers, setResolvers] = useState<Map<string, (value: unknown) => void>>(
    new Map()
  );

  const generateId = useCallback(() => {
    return Math.random().toString(36).slice(2) + Date.now().toString(36);
  }, []);

  const close = useCallback((id: string, result?: unknown) => {
    const resolver = resolvers.get(id);
    if (resolver) {
      resolver(result);
      setResolvers((prev) => {
        const next = new Map(prev);
        next.delete(id);
        return next;
      });
    }
    setOverlays((prev) => prev.filter((overlay) => overlay.id !== id));
  }, [resolvers]);

  const closeAll = useCallback(() => {
    resolvers.forEach((resolver) => resolver(undefined));
    setResolvers(new Map());
    setOverlays([]);
  }, [resolvers]);

  const open = useCallback(<T,>(
    render: (props: { close: (result?: T) => void; isOpen: boolean }) => ReactNode
  ): Promise<T | undefined> => {
    return new Promise((resolve) => {
      const id = generateId();

      const handleClose = (result?: T) => {
        close(id, result);
      };

      setResolvers((prev) => new Map(prev).set(id, resolve as (value: unknown) => void));
      setOverlays((prev) => [
        ...prev,
        {
          id,
          element: render({ close: handleClose, isOpen: true }),
        },
      ]);
    });
  }, [generateId, close]);

  // 전역 함수 등록
  globalOpen = open;
  globalClose = close;
  globalCloseAll = closeAll;

  const contextValue: OverlayContextType = {
    open,
    close,
    closeAll,
  };

  return (
    <OverlayContext.Provider value={contextValue}>
      {children}
      {overlays.length > 0 &&
        createPortal(
          <>
            {overlays.map((overlay) => (
              <div key={overlay.id} data-overlay-id={overlay.id}>
                {overlay.element}
              </div>
            ))}
          </>,
          document.body
        )}
    </OverlayContext.Provider>
  );
}

// ============ Hook ============
export function useOverlay() {
  const context = useContext(OverlayContext);
  if (!context) {
    throw new Error('useOverlay must be used within OverlayProvider');
  }
  return context;
}

// ============ Global overlay object ============
export const overlay = {
  open: <T,>(
    render: (props: { close: (result?: T) => void; isOpen: boolean }) => ReactNode
  ): Promise<T | undefined> => {
    if (!globalOpen) {
      throw new Error('OverlayProvider is not mounted');
    }
    return globalOpen(render);
  },
  close: (id: string) => {
    if (!globalClose) {
      throw new Error('OverlayProvider is not mounted');
    }
    globalClose(id);
  },
  closeAll: () => {
    if (!globalCloseAll) {
      throw new Error('OverlayProvider is not mounted');
    }
    globalCloseAll();
  },
};
```

## styled-components 버전

위 코드와 동일합니다. 스타일링만 styled-components로 변경하면 됩니다.

## Tailwind 버전

위 코드와 동일합니다. 컴포넌트 스타일링에서 className을 사용합니다.

## index.ts (export 파일)

```tsx
export { OverlayProvider, useOverlay, overlay } from './overlay';
export { Backdrop } from './Backdrop';
// 필요에 따라 예시 컴포넌트도 export
```
