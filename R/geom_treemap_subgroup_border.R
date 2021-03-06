#' @title Draw a border around a subgroup of treemap tiles.
#' @export
#'
#' @description
#'
#' Requires ‘area’ and ‘subgroup’. Strange things will happen if
#' \code{geom_treemap_subgroup_border} is given a different dataset or area
#' aesthetic than the \code{geom_treemap} it is drawn over.
#'
#' @seealso geom_treemap, geom_treemap_subgroup_text
#'
#' @param mapping,data,stat,position,na.rm,show.legend,inherit.aes,... Standard
#' geom arguments as for \code{geom_rect}.
#'
#' @section Aesthetics:
#'
#' \itemize{
#'   \item area (required)
#'   \item subgroup (required)
#'   \item colour
#'   \item size
#'   \item linetype
#'   \item alpha
#' }
geom_treemap_subgroup_border <- function(
  mapping = NULL,
  data = NULL,
  stat = "identity",
  position = "identity",
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE,
  ...
) {
  layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomTreemapSubgroupBorder,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      na.rm = na.rm,
      ...
    )
  )
}

#' @rdname ggplot2-ggproto
#' @format NULL
#' @usage NULL
#' @export
GeomTreemapSubgroupBorder <- ggproto(
  "GeomTreemapSubgroupBorder",
  Geom,
  required_aes = c("area", "subgroup"),
  default_aes = aes(
    colour = "grey50",
    fill = "",
    size = 4,
    linetype = 1,
    alpha = 1
  ),
  draw_key = draw_key_blank,

  draw_panel = function(data, panel_scales, coord) {

    data <- coord$transform(data, panel_scales)
    data$id <- 1:nrow(data)

    # Sum areas by subgroup
    data <- ddply(data, .(
      subgroup,
      PANEL,
      colour,
      size,
      linetype,
      alpha
    ), summarise, area = sum(as.numeric(area)), fill = head(fill, 1))
    data$id <- 1:nrow(data)

    # Generate treemap layout for data
    params <- list(
      data = data,
      area = "area",
      fill = "fill",
      xlim = c(0, 1),
      ylim = c(0, 1),
      label = "id",
      group = "subgroup"
    )
    layout <- do.call(treemapify, params)

    # Merge layout back into main data
    names(layout)[names(layout) == "label"] <- "id"
    layout <- layout[c("id", "xmin", "xmax", "ymin", "ymax")]
    data <- merge(data, layout, by = "id")

    # Draw rects
    grob <- grid::rectGrob(
      x = data$xmin,
      width = data$xmax - data$xmin,
      y = data$ymax,
      height = data$ymax - data$ymin,
      default.units = "native",
      just = c("left", "top"),
      gp = grid::gpar(
        col = data$colour,
        fill = NA,
        lwd = data$size,
        lty = data$linetype,
        lineend = "butt"
      )
    )
    grob$name <- grid::grobName(grob, "geom_treemap_subgroup_border")
    grob
  }
)
