#' Align Spatial Data
#'
#' `align` prepares a spatial object by aligning its CRS, extent, cell size, and grid offset based on a provided base layer.
#'
#' @param spatial_data A spatial object to be aligned.
#' @param base_layer A spatial object to use as a reference for extent, cell size, grid offset, and final CRS.
#' @param resample_method Character. Method used for estimating the new cell values. One of "near", "bilinear", "cubic", "cubicspline", "lanczos", "sum", "min", "q1", "med", "q3", "max", "average", "mode", "rms". Defaults to "bilinear".
#' @param show_plots Logical, whether to create and display before and after plots. Defaults to FALSE.
#' @param verbose Logical, whether to provide detailed logging. Defaults to TRUE.
#' @param output_file Optional. A file path to save the aligned spatial data.
#'
#' @return A spatial object aligned with the base layer's CRS, extent, cell size, and grid offset.
#' @examples
#' aligned_spatial_data <- align(spatial_data = spatial_data1, base_layer = spatial_data2, resample_method = "bilinear", show_plots = TRUE)
#' @export
align <- function(spatial_data, base_layer, resample_method = "bilinear", show_plots = FALSE, verbose = TRUE, output_file = NULL) {
    suppressMessages({
        library(terra)
        library(ggplot2)
        library(tidyterra)
        library(gridExtra)
        library(knitr)
    })

    # Verbose logging function
    log_message <- function(message) {
        if (verbose) {
            message(message)
        }
    }

    log_message("Starting alignment process.")

    if (!inherits(spatial_data, c("SpatVector", "SpatRaster"))) {
        stop("Input must be a spatial object.")
    }

    if (!inherits(base_layer, c("SpatVector", "SpatRaster"))) {
        stop("Base layer must be a spatial object.")
    }

    # Initialize list for the overview
    overview <- list()

    # Determine initial CRS and extent from base layer
    initial_crs <- terra::crs(base_layer, proj = TRUE)
    target_extent <- terra::ext(base_layer)

    log_message("Reprojecting base layer to spatial data CRS to minimize computational needs.")

    # Reproject base layer to spatial_data CRS
    target_crs <- terra::crs(spatial_data, proj = TRUE)

    tryCatch(
        {
            base_layer_proj <- terra::project(base_layer, target_crs)
        },
        error = function(e) {
            stop("Failed to project base layer to spatial data CRS:", e$message)
        }
    )

    # Process the spatial object
    original_crs <- terra::crs(spatial_data, proj = TRUE)
    original_extent <- terra::ext(spatial_data)

    # Create before plot using tidyterra and ggplot2
    if (show_plots) {
        log_message("Creating before plot.")
        if (inherits(spatial_data, "SpatRaster")) {
            before_plot <- ggplot() +
                tidyterra::geom_spatraster(data = spatial_data) +
                scale_fill_continuous() +
                ggtitle("Before Alignment") +
                theme_minimal()
        } else if (inherits(spatial_data, "SpatVector")) {
            before_plot <- ggplot() +
                tidyterra::geom_spatvector(data = spatial_data) +
                ggtitle("Before Alignment") +
                theme_minimal()
        }
    }

    log_message("Cropping spatial data to base layer extent.")

    # Step 1: Crop to target extent
    tryCatch(
        {
            spatial_data <- terra::crop(spatial_data, base_layer_proj)
        },
        error = function(e) {
            warning(paste("Failed to crop spatial object:", e$message))
            return(NULL)
        }
    )

    log_message("Reprojecting spatial data to initial CRS of base layer.")

    # Step 2: Reproject to initial CRS of base layer
    tryCatch(
        {
            spatial_data <- terra::project(spatial_data, initial_crs)
        },
        error = function(e) {
            warning(paste("Failed to project spatial object to initial CRS:", e$message))
            return(NULL)
        }
    )

    # Resample only if both spatial_data and base_layer are SpatRasters
    resample_done <- FALSE
    if (inherits(spatial_data, "SpatRaster") && inherits(base_layer, "SpatRaster")) {
        log_message("Resampling spatial data to match base layer's resolution and origin.")

        # Capture the original resolution
        original_res <- terra::res(spatial_data)

        # Step 3: Resample to match base layer's resolution and origin
        tryCatch(
            {
                spatial_data <- terra::resample(spatial_data, base_layer, method = resample_method)
                resample_done <- TRUE
            },
            error = function(e) {
                warning(paste("Failed to resample spatial object:", e$message))
                return(NULL)
            }
        )
    }

    log_message("Masking spatial data to base layer.")

    # Step 4: Mask to base layer
    tryCatch(
        {
            spatial_data <- terra::mask(spatial_data, base_layer)
        },
        error = function(e) {
            warning(paste("Failed to mask spatial object:", e$message))
            return(NULL)
        }
    )

    # Capture the changes in initial overview
    parameters_initial <- c("Original CRS", "New CRS", "Original Extent (xmin, ymin, xmax, ymax)", "New Extent (xmin, ymin, xmax, ymax)")
    values_initial <- c(original_crs, terra::crs(spatial_data, proj = TRUE), paste(original_extent), paste(terra::ext(spatial_data)))

    overview_initial <- data.frame(Parameter = parameters_initial, Value = values_initial, stringsAsFactors = FALSE)

    # Print the initial overview of changes
    print(knitr::kable(overview_initial, format = "markdown", caption = "Summary of Initial Alignment Changes"))

    # Capture the resampling changes in a separate overview
    if (resample_done) {
        new_res <- terra::res(spatial_data)
        parameters_resample <- c("Original Resolution (x, y)", "New Resolution (x, y)")
        values_resample <- c(paste(original_res), paste(new_res))

        overview_resample <- data.frame(Parameter = parameters_resample, Value = values_resample, stringsAsFactors = FALSE)

        # Print the resampling overview of changes
        print(knitr::kable(overview_resample, format = "markdown", caption = "Summary of Resampling Changes"))
    }

    if (!is.null(output_file)) {
        log_message(paste("Saving aligned spatial data to", output_file))
        terra::writeRaster(spatial_data, output_file, overwrite = TRUE)
    }

    # Create after plot using tidyterra and ggplot2
    if (show_plots) {
        log_message("Creating after plot.")
        if (inherits(spatial_data, "SpatRaster")) {
            after_plot <- ggplot() +
                tidyterra::geom_spatraster(data = spatial_data) +
                scale_fill_continuous() +
                ggtitle("After Alignment") +
                theme_minimal()
        } else if (inherits(spatial_data, "SpatVector")) {
            after_plot <- ggplot() +
                tidyterra::geom_spatvector(data = spatial_data) +
                ggtitle("After Alignment") +
                theme_minimal()
        }

        # Arrange before and after plots in a grid
        gridExtra::grid.arrange(before_plot, after_plot, ncol = 2)
    }

    log_message("Alignment process completed.")

    return(spatial_data)
}
