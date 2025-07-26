```typescript
import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

/**
 * Utility function to merge Tailwind CSS classes with clsx
 * Handles conditional classes and conflicts intelligently
 * 
 * @param inputs - Class values to merge
 * @returns Merged class string
 * 
 * @example
 * cn('px-2 py-1', 'bg-red-500', { 'text-white': true }) 
 * // Returns: "px-2 py-1 bg-red-500 text-white"
 * 
 * cn('px-2', 'px-4') 
 * // Returns: "px-4" (latter class overrides)
 */
export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs))
}

/**
 * Utility for conditional styling based on variants
 * Useful for component variants and state-based styling
 */
export const cva = (base: string, variants: Record<string, Record<string, string>>) => {
  return (props: Record<string, string | boolean>) => {
    let classes = base
    
    Object.keys(variants).forEach(key => {
      const value = props[key]
      if (value && variants[key][value as string]) {
        classes = cn(classes, variants[key][value as string])
      }
    })
    
    return classes
  }
}
```
