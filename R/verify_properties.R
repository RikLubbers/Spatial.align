#' Verify Spatial Data Properties
#'
#' `verify_properties` checks the properties of two spatial objects, such as CRS, extent, resolution, and data type, and provides a comparison summary of these properties.
#' If the spatial objects are rasters, it also provides a separate table for resolution.
#'
#' @param spatial_data1 A spatial object to be compared.
#' @param spatial_data2 A spatial object to be compared against.
#'
#' @examples
#' verify_properties(spatial_data1, spatial_data2)
#' @export
verify_properties <- function(spatial_data1, spatial_data2) {
    suppressMessages({
        library(terra)
        library(knitr)
        library(dplyr)
    })

    if (!inherits(spatial_data1, c("SpatVector", "SpatRaster"))) {
        stop("The first input must be a spatial object.")
    }

    if (!inherits(spatial_data2, c("SpatVector", "SpatRaster"))) {
        stop("The second input must be a spatial object.")
    }

    # Determine the type of spatial object
    data_type1 <- if (inherits(spatial_data1, "SpatVector")) {
        "Vector"
    } else if (inherits(spatial_data1, "SpatRaster")) {
        "Raster"
    } else {
        "Unknown"
    }

    data_type2 <- if (inherits(spatial_data2, "SpatVector")) {
        "Vector"
    } else if (inherits(spatial_data2, "SpatRaster")) {
        "Raster"
    } else {
        "Unknown"
    }

    # Get CRS
    crs_info1 <- tryCatch(
        {
            terra::crs(spatial_data1, proj = TRUE)
        },
        error = function(e) {
            "Error retrieving CRS"
        }
    )

    crs_info2 <- tryCatch(
        {
            terra::crs(spatial_data2, proj = TRUE)
        },
        error = function(e) {
            "Error retrieving CRS"
        }
    )

    # Get extent
    extent_info1 <- tryCatch(
        {
            terra::ext(spatial_data1)
        },
        error = function(e) {
            "Error retrieving extent"
        }
    )

    extent_info2 <- tryCatch(
        {
            terra::ext(spatial_data2)
        },
        error = function(e) {
            "Error retrieving extent"
        }
    )

    # Format extent to a single string
    extent_info1_str <- paste(c(extent_info1[1], extent_info1[2], extent_info1[3], extent_info1[4]), collapse = ", ")
    extent_info2_str <- paste(c(extent_info2[1], extent_info2[2], extent_info2[3], extent_info2[4]), collapse = ", ")

    # Get number of layers (only for rasters)
    n_layers1 <- tryCatch(
        {
            if (inherits(spatial_data1, "SpatRaster")) {
                terra::nlyr(spatial_data1)
            } else {
                NA
            }
        },
        error = function(e) {
            "Error retrieving number of layers"
        }
    )

    n_layers2 <- tryCatch(
        {
            if (inherits(spatial_data2, "SpatRaster")) {
                terra::nlyr(spatial_data2)
            } else {
                NA
            }
        },
        error = function(e) {
            "Error retrieving number of layers"
        }
    )

    # Create a comparison summary table
    summary_table <- data.frame(
        Property = c("Data Type", "CRS", "Extent", "Number of Layers"),
        Spatial_Data1 = c(data_type1, crs_info1, extent_info1_str, n_layers1),
        Spatial_Data2 = c(data_type2, crs_info2, extent_info2_str, n_layers2),
        stringsAsFactors = FALSE
    )

    # Highlight differences
    summary_table <- summary_table %>%
        mutate(Difference = ifelse(Spatial_Data1 != Spatial_Data2, "Different", "Same"))

    # Create a resolution comparison table if both are rasters
    if (inherits(spatial_data1, "SpatRaster") && inherits(spatial_data2, "SpatRaster")) {
        resolution_info1 <- tryCatch(
            {
                paste(terra::res(spatial_data1), collapse = ", ")
            },
            error = function(e) {
                "Error retrieving resolution"
            }
        )

        resolution_info2 <- tryCatch(
            {
                paste(terra::res(spatial_data2), collapse = ", ")
            },
            error = function(e) {
                "Error retrieving resolution"
            }
        )

        resolution_table <- data.frame(
            Property = c("Resolution"),
            Spatial_Data1 = c(resolution_info1),
            Spatial_Data2 = c(resolution_info2),
            stringsAsFactors = FALSE
        )

        # Highlight differences in resolution
        resolution_table <- resolution_table %>%
            mutate(Difference = ifelse(Spatial_Data1 != Spatial_Data2, "Different", "Same"))

        # Print the comparison summary table
        print(knitr::kable(summary_table, format = "markdown", caption = "Comparison of Spatial Data Properties"))

        # Print the resolution comparison table
        print(knitr::kable(resolution_table, format = "markdown", caption = "Comparison of Spatial Data Resolutions"))
    } else {
        # Print the comparison summary table
        print(knitr::kable(summary_table, format = "markdown", caption = "Comparison of Spatial Data Properties"))
    }
}
