import { motion } from "framer-motion";

interface GlassCardProps {
  children: React.ReactNode;
  className?: string;
  padding?: "none" | "sm" | "md" | "lg";
}

export function GlassCard({
  children,
  className = "",
  padding = "md",
}: GlassCardProps) {
  const paddingClass = {
    none: "",
    sm: "p-4",
    md: "p-6",
    lg: "p-8",
  }[padding];

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className={`rounded-2xl border border-white/10 bg-white/5 backdrop-blur-xl ${paddingClass} ${className}`}
    >
      {children}
    </motion.div>
  );
}
