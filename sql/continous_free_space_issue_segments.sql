select owner, s.tablespace_name, segment_name, s.bytes, next_extent, max(f.bytes) largest from dba_segments s, dba_free_space f where s.tablespace_name = f.tablespace_name(+) group by owner, s.tablespace_name, segment_name, s.bytes, next_extent having next_extent*2 >max(f.bytes);