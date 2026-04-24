/* STB JPEG encoder — included before ghosteye_frame_ffi.h to avoid conflicts
   with the malloc/free prototypes it pulls in via <stdlib.h>. */
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STBI_WRITE_NO_STDIO
#include "stb_image_write.h"

#include "ghosteye_frame_ffi.h"

#include <math.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

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

/* Fill an already-allocated RGB buffer from a BGRA8888 source. */
static void fill_rgb_from_bgra(const uint8_t* bgra,
                                int32_t src_width,
                                int32_t src_height,
                                int32_t bytes_per_row,
                                uint8_t* out,
                                int32_t out_width,
                                int32_t out_height) {
  const double scale_x = (double)src_width / out_width;
  const double scale_y = (double)src_height / out_height;

  for (int32_t y = 0; y < out_height; y++) {
    int32_t src_y = (int32_t)floor(y * scale_y);
    if (src_y >= src_height) {
      src_y = src_height - 1;
    }

    for (int32_t x = 0; x < out_width; x++) {
      int32_t src_x = (int32_t)floor(x * scale_x);
      if (src_x >= src_width) {
        src_x = src_width - 1;
      }

      const size_t offset =
          (size_t)src_y * (size_t)bytes_per_row + (size_t)src_x * 4u;
      const size_t out_offset =
          ((size_t)y * (size_t)out_width + (size_t)x) * 3u;

      out[out_offset]      = bgra[offset + 2u]; /* R */
      out[out_offset + 1u] = bgra[offset + 1u]; /* G */
      out[out_offset + 2u] = bgra[offset];      /* B */
    }
  }
}

/* Fill an already-allocated RGB buffer from YUV420 planes. */
static void fill_rgb_from_yuv420(const uint8_t* y_plane,
                                  int32_t y_bytes_per_row,
                                  const uint8_t* u_plane,
                                  int32_t u_bytes_per_row,
                                  int32_t safe_u_pixel_stride,
                                  const uint8_t* v_plane,
                                  int32_t v_bytes_per_row,
                                  int32_t safe_v_pixel_stride,
                                  int32_t src_width,
                                  int32_t src_height,
                                  uint8_t* out,
                                  int32_t out_width,
                                  int32_t out_height) {
  const double scale_x = (double)src_width / out_width;
  const double scale_y = (double)src_height / out_height;

  for (int32_t y = 0; y < out_height; y++) {
    int32_t src_y = (int32_t)floor(y * scale_y);
    if (src_y >= src_height) {
      src_y = src_height - 1;
    }
    const int32_t uv_row = src_y / 2;

    for (int32_t x = 0; x < out_width; x++) {
      int32_t src_x = (int32_t)floor(x * scale_x);
      if (src_x >= src_width) {
        src_x = src_width - 1;
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

      const size_t out_offset =
          ((size_t)y * (size_t)out_width + (size_t)x) * 3u;
      out[out_offset]      = (uint8_t)r;
      out[out_offset + 1u] = (uint8_t)g;
      out[out_offset + 2u] = (uint8_t)b;
    }
  }
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

  fill_rgb_from_bgra(bgra, width, height, bytes_per_row,
                     out_image->data, output_width, output_height);
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

  const int32_t safe_u = u_bytes_per_pixel > 0 ? u_bytes_per_pixel : 1;
  const int32_t safe_v = v_bytes_per_pixel > 0 ? v_bytes_per_pixel : 1;

  fill_rgb_from_yuv420(y_plane, y_bytes_per_row,
                       u_plane, u_bytes_per_row, safe_u,
                       v_plane, v_bytes_per_row, safe_v,
                       width, height,
                       out_image->data, output_width, output_height);
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

/* -------------------------------------------------------------------------
   Combined conversion + JPEG encoding
   ------------------------------------------------------------------------- */

typedef struct {
  uint8_t* data;
  int32_t  length;
  int32_t  capacity;
} _JpegWriteBuffer;

static void _jpeg_write_callback(void* context, void* data, int size) {
  _JpegWriteBuffer* buf = (_JpegWriteBuffer*)context;
  if (buf->data == NULL || size <= 0) {
    return;
  }
  if (buf->length + size > buf->capacity) {
    int32_t new_cap = buf->capacity * 2;
    if (new_cap < buf->length + size) {
      new_cap = buf->length + size;
    }
    uint8_t* p = (uint8_t*)realloc(buf->data, (size_t)new_cap);
    if (p == NULL) {
      free(buf->data);
      buf->data = NULL;
      return;
    }
    buf->data = p;
    buf->capacity = new_cap;
  }
  memcpy(buf->data + buf->length, data, (size_t)size);
  buf->length += size;
}

/* Encode a raw RGB buffer to JPEG using stb_image_write.
   On success returns GHOSTEYE_SUCCESS and populates out_image.
   The caller owns the buffer; release with ghosteye_jpeg_free_buffer(). */
static int32_t encode_rgb_to_jpeg(const uint8_t* rgb,
                                  int32_t width,
                                  int32_t height,
                                  int32_t quality,
                                  GhosteyeJpegImage* out_image) {
  /* Heuristic initial capacity: JPEG is typically much smaller than RGB. */
  const int32_t initial_cap = width * height;
  _JpegWriteBuffer buf;
  buf.data     = (uint8_t*)malloc((size_t)initial_cap);
  buf.length   = 0;
  buf.capacity = initial_cap;

  if (buf.data == NULL) {
    return GHOSTEYE_ERROR_ALLOCATION_FAILED;
  }

  active_allocations += 1;

  const int ok = stbi_write_jpg_to_func(
      _jpeg_write_callback, &buf, width, height, 3, rgb, quality);

  if (!ok || buf.data == NULL) {
    if (buf.data != NULL) {
      free(buf.data);
    }
    active_allocations -= 1;
    return GHOSTEYE_ERROR_ALLOCATION_FAILED;
  }

  out_image->data   = buf.data;
  out_image->length = buf.length;
  return GHOSTEYE_SUCCESS;
}

int32_t ghosteye_bgra8888_to_jpeg(const uint8_t* bgra,
                                   int32_t width,
                                   int32_t height,
                                   int32_t bytes_per_row,
                                   int32_t max_dimension,
                                   int32_t quality,
                                   GhosteyeJpegImage* out_image) {
  if (bgra == NULL || out_image == NULL || bytes_per_row <= 0 ||
      quality < 1 || quality > 100) {
    return GHOSTEYE_ERROR_INVALID_ARGUMENT;
  }

  int32_t ow = 0, oh = 0;
  int32_t status =
      compute_scaled_dimensions(width, height, max_dimension, &ow, &oh);
  if (status != GHOSTEYE_SUCCESS) {
    return status;
  }

  GhosteyeRgbImage rgb = {NULL, 0, 0, 0};
  status = allocate_rgb_image(ow, oh, &rgb);
  if (status != GHOSTEYE_SUCCESS) {
    return status;
  }

  fill_rgb_from_bgra(bgra, width, height, bytes_per_row, rgb.data, ow, oh);

  status = encode_rgb_to_jpeg(rgb.data, ow, oh, quality, out_image);

  /* Free the intermediate RGB buffer regardless of JPEG outcome. */
  free(rgb.data);
  active_allocations -= 1;

  return status;
}

int32_t ghosteye_yuv420_to_jpeg(const uint8_t* y_plane,
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
                                 int32_t quality,
                                 GhosteyeJpegImage* out_image) {
  if (y_plane == NULL || u_plane == NULL || v_plane == NULL ||
      out_image == NULL || y_bytes_per_row <= 0 || u_bytes_per_row <= 0 ||
      v_bytes_per_row <= 0 || quality < 1 || quality > 100) {
    return GHOSTEYE_ERROR_INVALID_ARGUMENT;
  }

  int32_t ow = 0, oh = 0;
  int32_t status =
      compute_scaled_dimensions(width, height, max_dimension, &ow, &oh);
  if (status != GHOSTEYE_SUCCESS) {
    return status;
  }

  GhosteyeRgbImage rgb = {NULL, 0, 0, 0};
  status = allocate_rgb_image(ow, oh, &rgb);
  if (status != GHOSTEYE_SUCCESS) {
    return status;
  }

  const int32_t safe_u = u_bytes_per_pixel > 0 ? u_bytes_per_pixel : 1;
  const int32_t safe_v = v_bytes_per_pixel > 0 ? v_bytes_per_pixel : 1;

  fill_rgb_from_yuv420(y_plane, y_bytes_per_row,
                       u_plane, u_bytes_per_row, safe_u,
                       v_plane, v_bytes_per_row, safe_v,
                       width, height,
                       rgb.data, ow, oh);

  status = encode_rgb_to_jpeg(rgb.data, ow, oh, quality, out_image);

  free(rgb.data);
  active_allocations -= 1;

  return status;
}

void ghosteye_jpeg_free_buffer(uint8_t* buffer) {
  if (buffer == NULL) {
    return;
  }
  free(buffer);
  if (active_allocations > 0) {
    active_allocations -= 1;
  }
}
