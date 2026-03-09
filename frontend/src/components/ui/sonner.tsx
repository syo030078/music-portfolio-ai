"use client";

import { Toaster as Sonner, type ToasterProps } from "sonner";

const Toaster = ({ ...props }: ToasterProps) => {
  return (
    <Sonner
      theme="light"
      className="toaster group"
      style={
        {
          "--normal-bg": "var(--popover, #fff)",
          "--normal-text": "var(--popover-foreground, #0a0a0a)",
          "--normal-border": "var(--border, #e5e5e5)",
        } as React.CSSProperties
      }
      {...props}
    />
  );
};

export { Toaster };
