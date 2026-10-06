export function LogoMark({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 32 32" className={className} aria-hidden="true">
      <rect width="32" height="32" rx="8" fill="#312e81" />
      <path
        d="M8 12h16M8 16h16M8 20h10"
        stroke="#6ee7b7"
        strokeWidth="2"
        strokeLinecap="round"
      />
    </svg>
  );
}
