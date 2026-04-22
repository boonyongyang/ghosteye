#include "ghosteye_frame_ffi.h"

#include <math.h>
#include <stddef.h>
#include <stdlib.h>

enum {
  GHOSTEYE_SUCCESS = 0,
  GHOSTEYE_ERROR_INVALID_ARGUMENT = -1,
  GHOSTEYE_ERROR_ALLOCATION_FAILED = -2,
};

static int32_t active_allocations = 0;

static int32_t clamp_channel(int32_t value) {
  if (value < 0) {
    return 0;
  }
  if (value > 255) {
    return 255;
  }
  return value;
}

static int32_t compute_scaled_dimensions(int32_t width,
                                         int32_t height,
                                         int32_t max_dimension,
                                         int32_t* out_width,
                                         int32_t* out_height) {
  if (width <= 0 || height <= 0 || max_dimension <= 0 || out_width == NULL ||
      out_height == NULL) {
    return GHOSTEYE_ERROR_INVALID_ARGUMENT;
  }

  const double longest_side = (double)(width > height ? width : height);
  const double scale =
      longest_side <= max_dimension ? 1.0 : longest_side / max_dimension;

  int32_t scaled_width = (int32_t)lround((double)width / scale);
  int32_t scaled_height = (int32_t)lround((double)height / scale);

  if (scaled_width < 1) {
    scaled_width = 1;
  }
  if (scaled_height < 1) {
    scaled_height = 1;
  }

  *out_width = scaled_width;
  *out_height = scaled_height;
  return GHOSTEYE_SUCCESS;
}

static int32_t allocate_rgb_image(int32_t width,
                                  int32_t height,
                                  GhosteyeRgbImage* out_image) {
  if (out_image == NULL) {
    return GHOSTEYE_ERROR_INVALID_ARGUMENT;
  }

  const size_t length = (size_t)width * (size_t)height * 3u;
  if (length == 0u) {
    return GHOSTEYE_ERROR_INVALID_ARGUMENT;
  }

  uint8_t* buffer = (uint8_t*)malloc(length);
  if (buffer == NULL) {
    return GHOSTEYE_ERROR_ALLOCATION_FAILED;
  }

  out_image->data = buffer;
  out_image->length = (int32_t)length;
  out_image->width = width;
  out_image->height = height;
  active_allocations += 1;
  return GHOSTEYE_SUCCESS;
}

int32_t ghosteye_bgra8888_to_rgb(const uint8_t* bgra,
                                 int32_t width,
                                 int32_t height,
                                 int32_t bytes_per_row,
                                 int32_t max_dimension,
                                 GhosteyeRgbImage* out_image) {
  if (bgra == NULL || out_image == NULL || bytes_per_row <= 0) {
    return GHOSTEYE_ERROR_INVALID_ARGUMENT;
  }

  int32_t output_width = 0;
  int32_t output_height = 0;
  int32_t status = compute_scaled_dimensions(width, height, max_dimension,
                                             &output_width, &output_height);
  if (status != GHOSTEYE_SUCCESS) {
    return status;
  }

  status = allocate_rgb_image(output_width, output_height, out_image);
  if (status != GHOSTEYE_SUCCESS) {
    return status;
  }

  const double scale_x = (double)width / output_width;
  const double scale_y = (double)height / output_height;
  uint8_t* out = out_image->data;

  for (int32_t y = 0; y < output_height; y++) {
    int32_t src_y = (int32_t)floor(y * scale_y);
    if (src_y >= height) {
      src_y = height - 1;
    }

    for (int32_t x = 0; x < output_width; x++) {
      int32_t src_x = (int32_t)floor(x * scale_x);
      if (src_x >= width) {
        src_x = width - 1;
      }

      const size_t offset =
          (size_t)src_y * (size_t)bytes_per_row + (size_t)src_x * 4u;
      const size_t out_offset = ((size_t)y * (size_t)output_width +
                                 (size_t)x) *
                                3u;

      out[out_offset] = bgra[offset + 2u];
      out[out_offset + 1u] = bgra[offset + 1u];
      out[out_offset + 2u] = bgra[offset];
    }
  }

  return GHOSTEYE_SUCCESS;
}

int32_t ghosteye_yuv420_to_rgb(const uint8_t* y_plane,
                               int32_t y_bytes_per_row,
                               const uint8_t* u_plane,
                               int32_t u_bytes_per_row,
                               int32_t u_bytes_per_pixel,
                               const uint8_t* v_plane,
                               int32_t v_bytes_per_row,
                               int32_t v_bytes_per_pixel,
                               int32_t width,
                               int32_t height,
                               int32_t max_dimension,
                               GhosteyeRgbImage* out_image) {
  if (y_plane == NULL || u_plane == NULL || v_plane == NULL ||
      out_image == NULL || y_bytes_per_row <= 0 || u_bytes_per_row <= 0 ||
      v_bytes_per_row <= 0) {
    return GHOSTEYE_ERROR_INVALID_ARGUMENT;
  }

  int32_t output_width = 0;
  int32_t output_height = 0;
  int32_t status = compute_scaled_dimensions(width, height, max_dimension,
                                             &output_width, &output_height);
  if (status != GHOSTEYE_SUCCESS) {
    return status;
  }

  status = allocate_rgb_image(output_width, output_height, out_image);
  if (status != GHOSTEYE_SUCCESS) {
    return status;
  }

  const int32_t safe_u_pixel_stride =
      u_bytes_per_pixel > 0 ? u_bytes_per_pixel : 1;
  const int32_t safe_v_pixel_stride =
      v_bytes_per_pixel > 0 ? v_bytes_per_pixel : 1;
  const double scale_x = (double)width / output_width;
  const double scale_y = (double)height / output_height;
  uint8_t* out = out_image->data;

  for (int32_t y = 0; y < output_height; y++) {
    int32_t src_y = (int32_t)floor(y * scale_y);
    if (src_y >= height) {
      src_y = height - 1;
    }
    const int32_t uv_row = src_y / 2;

    for (int32_t x = 0; x < output_width; x++) {
      int32_t src_x = (int32_t)floor(x * scale_x);
      if (src_x >= width) {
        src_x = width - 1;
      }
      const int32_t uv_col = src_x / 2;

      const uint8_t y_value =
          y_plane[(size_t)src_y * (size_t)y_bytes_per_row + (size_t)src_x];
      const uint8_t u_value =
          u_plane[(size_t)uv_row * (size_t)u_bytes_per_row +
                  (size_t)uv_col * (size_t)safe_u_pixel_stride];
      const uint8_t v_value =
          v_plane[(size_t)uv_row * (size_t)v_bytes_per_row +
                  (size_t)uv_col * (size_t)safe_v_pixel_stride];

      const int32_t r = clamp_channel(
          (int32_t)lround(y_value + 1.402 * ((double)v_value - 128.0)));
      const int32_t g = clamp_channel((int32_t)lround(
          y_value - 0.344136 * ((double)u_value - 128.0) -
          0.714136 * ((double)v_value - 128.0)));
      const int32_t b = clamp_channel(
          (int32_t)lround(y_value + 1.772 * ((double)u_value - 128.0)));

      const size_t out_offset = ((size_t)y * (size_t)output_width +
                                 (size_t)x) *
                                3u;
      out[out_offset] = (uint8_t)r;
      out[out_offset + 1u] = (uint8_t)g;
      out[out_offset + 2u] = (uint8_t)b;
    }
  }

  return GHOSTEYE_SUCCESS;
}

void ghosteye_frame_free_buffer(uint8_t* buffer) {
  if (buffer == NULL) {
    return;
  }
  free(buffer);
  if (active_allocations > 0) {
    active_allocations -= 1;
  }
}

int32_t ghosteye_frame_active_allocations(void) { return active_allocations; }
