module VersionsHelper
  def atom_link(rubygem)
    link_to t(".links.rss"), rubygem_versions_path(rubygem, format: "atom"),
            class: "gem__link t-list__item", id: :rss
  end

  def show_all_versions_link?(rubygem)
    rubygem.versions_count > 5 || rubygem.yanked_versions?
  end

  def latest_version_number(rubygem)
    return rubygem.version if rubygem.respond_to?(:version)
    (rubygem.latest_version || rubygem.versions.last)&.number
  end
end
