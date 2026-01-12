if (variable_instance_exists(id, "floorVBuffer")) {
    vertex_delete_buffer(floorVBuffer);
}
if (variable_instance_exists(id, "floorFormat")) {
    vertex_format_delete(floorFormat);
}
if (variable_instance_exists(id, "camera")) {
    camera_destroy(camera);
}
