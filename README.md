# spatial.align

## Overview
`spatial.align` is an R package providing functions for spatial data alignment and verification. This package includes the `align` and `verify_properties` functions, designed to facilitate spatial data pre-processing tasks. It is based on the `Raster Alignment` tool from `QGis` [QGIS User Manual on Raster Analysis](https://docs.qgis.org/2.18/en/docs/user_manual/working_with_raster/raster_analysis.html#id3). This package is helpful when being provided with a raster file bigger than your study area. The raster file can then be aligned with a your smaller study area. 

## Installation

You can install the package directly from GitHub using the `devtools` package:

```r
# Install devtools if you haven't already
install.packages("devtools")

# Install spatial.align from GitHub
devtools::install_github("RikLubbers/spatial.align")
```

## Functions

### `align`
Aligns spatial data based on specified parameters, including CRS, extent, cell size, and grid offset, using a provided base layer.

#### Usage
```r
align(spatial_data, base_layer, resample_method = "bilinear", show_plots = FALSE, verbose = TRUE, output_file = NULL)
```

#### Arguments
- `spatial_data`: A spatial object to be aligned.
- `base_layer`: A spatial object to use as a reference.
- `resample_method`: Method for resampling cell values. Defaults to "bilinear".
- `show_plots`: Whether to create and display before and after plots. Defaults to FALSE.
- `verbose`: Whether to provide detailed logging. Defaults to TRUE.
- `output_file`: Optional. A file path to save the aligned spatial data.

#### Value
Returns a spatial object aligned with the base layer's CRS, extent, cell size, and grid offset.

#### Examples
```r
aligned_spatial_data <- align(spatial_data = spatial_data1, base_layer = spatial_data2, resample_method = "bilinear", show_plots = TRUE)
```

### `verify_properties`
Checks the properties of two spatial objects, such as CRS, extent, resolution, and data type, and provides a comparison summary.

#### Usage
```r
verify_properties(spatial_data1, spatial_data2)
```

#### Arguments
- `spatial_data1`: A spatial object to be compared.
- `spatial_data2`: A spatial object to be compared against.

#### Examples
```r
verify_properties(spatial_data1, spatial_data2)
```

## Example

```r
# Load the package
library(spatial.align)

# Example usage of align function
aligned_spatial_data <- align(spatial_data = spatial_data1, base_layer = spatial_data2, resample_method = "bilinear", show_plots = TRUE)

# Example usage of verify_properties function
verify_properties(spatial_data1, spatial_data2)
```

## Contributing
Contributions are welcome! Please submit pull requests or open issues to discuss potential changes.

## License
This project is licensed under the MIT License.
