module SplatsHelper
  SPLAT_ROTATION = %w[90 80 75 60 45 35 25 5 -45 -40 -75]
  SPLAT_SIZE = [14, 16, 18, 20, 22]
  MIN_THRESHOLD = 7

  def splat_rotation(splat)
    "--splat-rotate: #{ SPLAT_ROTATION[Zlib.crc32(splat.to_param) % SPLAT_ROTATION.size] }deg;"
  end

  def splat_size(splat)
    "--splat-size: #{ SPLAT_SIZE.min_by { |size| (size - (splat.boosts.size + splat.comments.size + MIN_THRESHOLD)).abs } }cqi;"
  end
end
