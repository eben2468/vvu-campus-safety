import { ApiError } from "./api/errors";
import { ApiRequest, requireCaller } from "./api/request";
import { canUploadPhoto, parsePhotoUpload } from "./photoLogic";
import { getFileStore } from "./photoStore";

/**
 * Stores an incident or chat photo and returns its URL, which the app then
 * saves on the incident or message. Reports upload their photos before the
 * incident exists, so this can't check the incident itself.
 */
export async function uploadPhoto(request: ApiRequest) {
  const caller = requireCaller(request);
  if (!canUploadPhoto(caller.role, caller.verified)) {
    throw new ApiError("permission-denied", "Verify your ID before uploading photos.");
  }
  const parsed = parsePhotoUpload(request.data);
  if (!parsed.ok) throw new ApiError("invalid-argument", parsed.message);
  try {
    const url = await getFileStore().save(parsed.value.path, parsed.value.bytes, "image/jpeg");
    return { url };
  } catch (error) {
    console.error("Could not store a photo", error);
    const { name, message } = error as Error;
    throw new ApiError("internal", `The server could not store the photo (${name}: ${message}).`);
  }
}
