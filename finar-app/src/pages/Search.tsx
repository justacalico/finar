import { useState, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { Search as SearchIcon } from "lucide-react";
import { useLibraryStore } from "../stores/library";
import { useTranslation } from "../translations";
import { MediaCard } from "../components/MediaCard";
import { Input } from "../components/Input";

export function Search() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { searchResults, searchQuery, search, clearSearch, isLoading } =
    useLibraryStore();
  const [query, setQuery] = useState(searchQuery);

  const handleSearch = useCallback(
    (value: string) => {
      setQuery(value);
      if (value.length >= 2) search(value);
      else clearSearch();
    },
    [search, clearSearch]
  );

  return (
    <div className="mx-auto max-w-6xl px-4 py-6 md:px-8">
      <h1 className="mb-6 text-2xl font-bold text-text-primary">{t("search.title")}</h1>
      <div className="mb-8">
        <Input
          placeholder={t("search.placeholder")}
          value={query}
          onChange={(e) => handleSearch(e.target.value)}
          leftIcon={<SearchIcon className="h-5 w-5" />}
        />
      </div>

      {isLoading && (
        <div className="flex justify-center py-12">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        </div>
      )}

      {!isLoading && searchResults.length === 0 && query.length >= 2 && (
        <div className="flex flex-col items-center justify-center py-16 text-center">
          <SearchIcon className="h-16 w-16 text-text-tertiary/50" />
          <p className="mt-4 text-text-secondary">{t("search.noResults")}</p>
        </div>
      )}

      {!isLoading && query.length < 2 && (
        <div className="flex flex-col items-center justify-center py-16 text-center">
          <SearchIcon className="h-16 w-16 text-text-tertiary/50" />
          <p className="mt-4 text-text-primary">{t("search.searchYourMedia")}</p>
          <p className="mt-1 text-sm text-text-tertiary">
            {t("search.findMoviesShowsMusic")}
          </p>
        </div>
      )}

      {!isLoading && searchResults.length > 0 && (
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5">
          {searchResults.map((item, i) => (
            <MediaCard
              key={item.Id}
              item={item}
              index={i}
              onClick={() => navigate(`/item/${item.Id}`)}
            />
          ))}
        </div>
      )}
    </div>
  );
}
