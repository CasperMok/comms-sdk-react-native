package io.dolby.sdk.reactnative.mapper

import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap
import com.voxeet.sdk.json.ParticipantInvited

/**
 * Provides methods that map React Native model to [ParticipantInvited] model
 */
class InvitationMapper(
  private val permissionMapper: ConferencePermissionMapper,
  private val participantMapper: ParticipantMapper
) {

  private companion object {
    private const val PARTICIPANT_INFO = "info"
    private const val PARTICIPANT_PERMISSIONS = "permissions"
  }

  fun fromNative(invitedParticipantsArray: ReadableArray): List<ParticipantInvited> {
    return invitedParticipantsArray.toArrayList()
      .filterIsInstance<ReadableMap>()
      .mapNotNull { map ->
        val info = map.getMap(PARTICIPANT_INFO)?.let(participantMapper::toParticipantInfo)
        val permissions = map.getArray(PARTICIPANT_PERMISSIONS)?.let(permissionMapper::fromNative)
        info?.let(::ParticipantInvited)?.apply { setPermissions(permissions) }
      }
  }
}
