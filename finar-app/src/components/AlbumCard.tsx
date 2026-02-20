import { motion } from "framer-motion";
import { Disc } from "lucide-react";
import type { MediaItem } from "../types/jellyfin";
import { getDisplayImageUrl } from "../utils/image";

interface AlbumCardProps {
  item: MediaItem;
  index?: number;
  onClick?: () => void;
  className?: string;
}

export function AlbumCard({
  item,
  index = 0,
  onClick,
  className = "",
}: AlbumCardProps) {
  const imageUrl = getDisplayImageUrl(item, { maxWidth: 400 });
  const subtitle = [item.AlbumArtist, ...(item.Artists ?? [])]
    .filter(Boolean)
    .join(", ") || item.ProductionYear?.toString();

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, delay: index * 0.03 }}
      className={`group cursor-pointer ${className}`}
      onClick={onClick}
    >
      <div className="relative aspect-square overflow-hidden rounded-xl bg-surface-elevated shadow-lg transition transform group-hover:scale-[1.02] group-hover:shadow-xl">
        {!imageUrl ? (
          <div className="flex h-full w-full items-center justify-center bg-surface text-text-tertiary">
            <Disc className="h-16 w-16 shrink-0 opacity-60" />
          </div>
        ) : (
          <img
            src={imageUrl}
            alt={item.Name}
            className="h-full w-full object-cover"
            loading="lazy"
            onError={(e) => {
              (e.target as HTMLImageElement).src =
                "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 200 200' fill='%23242428'%3E%3Crect width='200' height='200'/%3E%3Ccircle cx='100' cy='100' r='60' fill='%23333338'/%3E%3Ccircle cx='100' cy='100' r='20' fill='%23242428'/%3E%3Ctext x='50%25' y='50%25' dominant-baseline='middle' text-anchor='middle' fill='%23707070' font-size='12'%3EAlbum%3C/text%3E%3C/svg%3E";
            }}
          />
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent opacity-0 transition-opacity group-hover:opacity-100 rounded-xl" />
      </div>
      <div className="mt-2 px-0.5">
        <p className="truncate text-sm font-medium text-text-primary">
          {item.Name}
        </p>
        {subtitle && (
          <p className="truncate text-xs text-text-tertiary">{subtitle}</p>
        )}
      </div>
    </motion.div>
  );
}
