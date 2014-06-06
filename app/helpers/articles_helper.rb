module ArticlesHelper
  def article_category_menu(selected, default="article.category.any")
    cats = Article::CATEGORIES.map { |cat| [t("article.category.#{cat}"), cat] }
    cats.unshift [t(default), ""] if default
    options_for_select(cats, selected)
  end
end
