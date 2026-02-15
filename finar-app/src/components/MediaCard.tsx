import { motion } from "framer-motion";
import { ListMusic, Bookmark } from "lucide-react";
import type { MediaItem } from "../types/jellyfin";
import { getDisplayImageUrl } from "../utils/image";

interface MediaCardProps {
  item: MediaItem;
  title?: string;
  subtitle?: string;
  progress?: number;
  showProgress?: boolean;
  index?: number;
  onClick?: () => void;
  className?: string;
}

export function MediaCard({
  item,
  title,
  subtitle,
  progress = 0,
  showProgress,
  index = 0,
  onClick,
  className = "",
}: MediaCardProps) {
  const displayTitle = title ?? item.Name;
  const displaySubtitle =
    subtitle ??
    (item.Type === "Episode" && item.SeriesName
      ? `S${item.ParentIndexNumber ?? 0} E${item.IndexNumber ?? 0}`
      : item.ProductionYear?.toString());
  const imageUrl = getDisplayImageUrl(item, { maxWidth: 400 });
  const isPlaylist = item.Type === "Playlist";
  const isWatchlist = displayTitle.toLowerCase().includes("watchlist");
  const showIconPlaceholder =
    !imageUrl || (isPlaylist && !item.ImageTags?.Primary);
  const PlaceholderIcon = isWatchlist ? Bookmark : ListMusic;

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, delay: index * 0.03 }}
      className={`group cursor-pointer ${className}`}
      onClick={onClick}
    >
      <div className="relative aspect-[2/3] overflow-hidden rounded-xl bg-surface-elevated shadow-lg transition transform group-hover:scale-[1.02] group-hover:shadow-xl">
        {showIconPlaceholder ? (
          <div className="flex h-full w-full items-center justify-center bg-surface text-text-tertiary">
            <PlaceholderIcon className="h-16 w-16 shrink-0 opacity-60" />
          </div>
        ) : (
          <img
            src={imageUrl}
            alt={displayTitle}
            className="h-full w-full object-cover"
            loading="lazy"
            onError={(e) => {
              (e.target as HTMLImageElement).src =
                "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 200 300' fill='%23242428'%3E%3Crect width='200' height='300'/%3E%3Ctext x='50%25' y='50%25' dominant-baseline='middle' text-anchor='middle' fill='%23707070' font-size='14'%3ENo image%3C/text%3E%3C/svg%3E";
            }}
          />
        )}
        {showProgress && progress > 0 && progress < 1 && (
          <div className="absolute bottom-0 left-0 right-0 h-1 bg-black/50">
            <div
              className="h-full bg-primary transition-all"
              style={{ width: `${progress * 100}%` }}
            />
          </div>
        )}
        <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent opacity-0 transition-opacity group-hover:opacity-100" />
      </div>
      <div className="mt-2 px-0.5">
        <p className="truncate text-sm font-medium text-text-primary">
          {displayTitle}
        </p>
        {displaySubtitle && (
          <p className="truncate text-xs text-text-tertiary">{displaySubtitle}</p>
        )}
      </div>
    </motion.div>
  );
}
