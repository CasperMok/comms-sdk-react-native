import Foundation
import VoxeetSDK

// MARK: - Supported Events
private enum EventKeys: String, CaseIterable {
	/// Emitted when a new participant is invited to a conference or joins a conference.
	case participantAdded = "EVENT_CONFERENCE_PARTICIPANT_ADDED"
	/// Emitted when a participant changes VTConferenceStatus.
	case participantUpdated = "EVENT_CONFERENCE_PARTICIPANT_UPDATED"
	/// Emitted when the local participant"s permissions are updated.
	case permissionsUpdated = "EVENT_CONFERENCE_PERMISSIONS_UPDATED"
	/// Emitted when ta conference changes status.
	case statusUpdated = "EVENT_CONFERENCE_STATUS_UPDATED"
	/// Emitted when the SDK adds a new stream to a conference participant.
	case streamAdded = "EVENT_CONFERENCE_STREAM_ADDED"
	/// Emitted when a conference participant who is connected to the audio and video stream changes the stream by enabling a microphone while using a camera or by enabling a camera while using a microphone.
	case streamUpdated = "EVENT_CONFERENCE_STREAM_UPDATED"
	/// Emitted when the SDK removes a stream from a conference participant.
	case streamRemoved = "EVENT_CONFERENCE_STREAM_REMOVED"
}

@objc(RNConferenceServiceModule)
public class ConferenceServiceModule: ReactEmitter {
	var current: VTConference? {
		VoxeetSDK.shared.conference.current
	}

	// MARK: - Events Setup
	@objc(supportedEvents)
	override public func supportedEvents() -> [String] {
		return EventKeys.allCases.mapToStrings()
	}

	public override func startObserving() {
		super.startObserving()
		VoxeetSDK.shared.conference.delegate = self;
	}

	public override func stopObserving() {
		super.stopObserving()
		VoxeetSDK.shared.conference.delegate = nil;
	}

	// MARK: - Methods
	/// Creates a conference.
	/// - Parameters:
	///   - options: conference options
	///   - resolve: returns conference object
	///   - reject: returns error on failure
	@objc(create:resolver:rejecter:)
	public func create(
		options: [String: Any]?,
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		VoxeetSDK.shared.conference.create(options: VTConferenceOptions.create(with: options)) { conference in
			resolve(conference.toReactModel())
		} fail: { error in
			error.send(with: reject)
		}
	}
	
	/// Provides the conference object that allows joining a conference.
	/// - Parameters:
	///   - conferenceId: conference id
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(fetch:resolver:rejecter:)
	public func fetch(
		conferenceId: String,
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		VoxeetSDK.shared.conference.fetch(conferenceID: conferenceId) { conference in
			resolve(conference.toReactModel())
		}
	}
	
	/// Joins a conference.
	/// - Parameters:
	///   - conference: conference object
	///   - options: join options
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(join:options:resolver:rejecter:)
	public func join(
		conference: [String: Any],
		options: [String: Any]?,
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		guard let conferenceId = conference.identifier else {
			ModuleError.noConferenceId.send(with: reject)
			return
		}
		VoxeetSDK.shared.conference.fetch(conferenceID: conferenceId) { conference in
			VoxeetSDK.shared.conference.join(
				conference: conference,
				options: VTJoinOptions.create(with: options)) { conference in
					resolve(conference.toReactModel())
				} fail: { error in
					error.send(with: reject)
				}
		}
	}

    /// Joins the conference in the listener mode in which the conference participant can only receive video and audio and cannot transmit any media.
    /// - Parameters:
    ///   - conference: conference object
    ///   - options: listen options
    ///   - resolve: returns on success
    ///   - reject: returns error on failure
    @objc(listen:options:resolver:rejecter:)
    public func listen(
        conference: [String: Any],
        options: [String: Any]?,
        resolve: @escaping RCTPromiseResolveBlock,
        reject: @escaping RCTPromiseRejectBlock
    ) {
        guard let conferenceId = conference.identifier else {
            ModuleError.noConferenceId.send(with: reject)
            return
        }
        VoxeetSDK.shared.conference.fetch(conferenceID: conferenceId) { conference in
            VoxeetSDK.shared.conference.listen(
                conference: conference,
                options: VTListenOptions.create(with: options)) { conference in
                    resolve(conference.toReactModel())
                } fail: { error in
                    error.send(with: reject)
                }
        }
    }

	/// Kicks the participant from a conference.
	/// - Parameters:
	///   - participant: Remote participant to kick.
	///   - resolve: returns current conference object
	///   - reject: returns error on failure
	@objc(kick:resolver:rejecter:)
	public func kick(
		participant: [String: Any],
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		guard let participantObject = current?.findParticipant(with: participant.identifier) else {
			ModuleError.noParticipant(participant.description).send(with: reject)
			return
		}
		VoxeetSDK.shared.conference.kick(participant: participantObject) { error in
			guard let error = error else {
				resolve(NSNull())
				return
			}
			error.send(with: reject)
		}
	}
	
	/// Leaves the current conference.
	/// - Parameters:
	///   - resolve: returns current conference object
	///   - reject: returns error on failure
	@objc(leave:rejecter:)
	public func leave(
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		VoxeetSDK.shared.conference.leave { error in
			guard let error = error else {
				resolve(NSNull())
				return
			}
			error.send(with: reject)
		}
	}
	
	/// Replays the conference.
	/// - Parameters:
	///   - conference: conference object
	///   - replayOptions: The replay options.
	///   - resolve: returns current conference object
	///   - reject: returns error on failure
	@objc(replay:replayOptions:resolver:rejecter:)
	public func replay(
		conference: [String: Any],
		replayOptions: [String: Any]?,
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		guard let conferenceId = conference.identifier else {
			ModuleError.noConferenceId.send(with: reject)
			return
		}
		VoxeetSDK.shared.conference.fetch(conferenceID: conferenceId) { [weak self] conference in
			VoxeetSDK.shared.conference.replay(
				conference: conference,
				options: VTReplayOptions.create(with: replayOptions)) { error in
					guard let error = error else {
						resolve(self?.current?.toReactModel())
						return
					}
					error.send(with: reject)
				}
		}
	}
	
	// MARK: - User Actions
	
	/// Updates the participant's conference permissions.
	/// - Parameters:
	///   - participantPermissions: The updated participant's permissions.
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(updatePermissions:resolver:rejecter:)
	public func updatePermissions(
		participantPermissions: [[String: Any]],
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		guard let conference = current else {
			ModuleError.noCurrentConference.send(with: reject)
			return
		}
		let permissions = VTParticipantPermissions.permissions(with: participantPermissions, conference: conference)
		VoxeetSDK.shared.conference.updatePermissions(participantPermissions: permissions) { error in
			guard let error = error else {
				resolve(NSNull())
				return
			}
			error.send(with: reject)
		}
	}
	
	/// Starts audio transmission between the local client and a conference.
	/// - Parameters:
	///   - participant: the participant you want to mute.
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(startAudio:resolver:rejecter:)
	public func startAudio(
		participant: [String: Any],
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		VoxeetSDK.shared.conference.startAudio(
			participant: current?.findParticipant(with: participant.identifier)
		) { error in
			guard let error = error else {
				resolve(NSNull())
				return
			}
			error.send(with: reject)
		}
	}
	
	/// Notifies the server to either start sending the local participant's video stream to the conference or start sending a remote participant's video stream to the local participant.
	/// - Parameters:
	///   - participant: the selected participant.
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(startVideo:resolver:rejecter:)
	public func startVideo(
		participant: [String: Any],
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		VoxeetSDK.shared.conference.startVideo(
			participant: current?.findParticipant(with: participant.identifier)
		) { error in
			guard let error = error else {
				resolve(NSNull())
				return
			}
			error.send(with: reject)
		}
	}
	
	/// Stops audio transmission between the local client and a conference.
	/// - Parameters:
	///   - participant: the selected participant.
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(stopAudio:resolver:rejecter:)
	public func stopAudio(
		participant: [String: Any],
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		VoxeetSDK.shared.conference.stopAudio(
			participant: current?.findParticipant(with: participant.identifier)
		) { error in
			guard let error = error else {
				resolve(NSNull())
				return
			}
			error.send(with: reject)
		}
	}
	
	/// Notifies the server to either stop sending the local participant's video stream to the conference or stop sending a remote participant's video stream to the local participant.
	/// - Parameters:
	///   - participant: the selected participant.
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(stopVideo:resolver:rejecter:)
	public func stopVideo(
		participant: [String: Any],
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		VoxeetSDK.shared.conference.stopVideo(
			participant: current?.findParticipant(with: participant.identifier)
		) { error in
			guard let error = error else {
				resolve(NSNull())
				return
			}
			error.send(with: reject)
		}
	}
	
	// MARK: - Getters
	
	/// Returns information about the current conference.
	/// - Parameters:
	///   - resolve: returns current conference object
	///   - reject: returns error on failure
	@objc(current:rejecter:)
	public func current(
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		guard let conference = current else {
			ModuleError.noCurrentConference.send(with: reject)
			return
		}
		resolve(conference.toReactModel())
	}
	
	/// Gets the participant's audio level. The audio level value ranges from 0.0 to 1.0.
	/// - Parameters:
	///   - participant: participant object
	///   - resolve: returns participant's audio level on success
	///   - reject: returns error on failure
	@objc(getAudioLevel:resolver:rejecter:)
	public func getAudioLevel(
		participant: [String: Any],
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		guard let participantObject = current?.findParticipant(with: participant.identifier) else {
			ModuleError.noParticipant(participant.description).send(with: reject)
			return
		}
		resolve(NSNumber(value: VoxeetSDK.shared.conference.audioLevel(participant: participantObject)))
	}
	
	/// Provides the maximum number of video streams that may be transmitted to the local participant.
	/// - Parameters:
	///   - resolve: returns the maximum number of video streams on success
	///   - reject: returns error on failure
	@objc(getMaxVideoForwarding:rejecter:)
	public func getMaxVideoForwarding(
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		resolve(NSNumber(value: VoxeetSDK.shared.conference.maxVideoForwarding))
	}
	
	/// Provides the participant with participant's id from the current conference.
	/// - Parameters:
	///   - participantId: participant's id
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(getParticipant:resolver:rejecter:)
	public func getParticipant(
		participantId: String,
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		guard let participantObject = current?.findParticipant(with: participantId) else {
			ModuleError.noParticipantId(participantId).send(with: reject)
			return
		}
		resolve(participantObject.toReactModel())
	}
	
	/// Provides the list of participants from the conference.
	/// - Parameters:
	///   - conference: conference object
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(getParticipants:resolver:rejecter:)
	public func getParticipants(
		conference: [String: Any],
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		guard let conferenceId = conference.identifier else {
			ModuleError.noConferenceId.send(with: reject)
			return
		}
		if let current = current, current.id == conferenceId {
			resolve(current.participants.map { $0.toReactModel() })
			return
		}
		VoxeetSDK.shared.conference.fetch(conferenceID: conferenceId) { conference in
			resolve(conference.participants.map { $0.toReactModel() })
		}
	}
	
	/// Provides the status of the conference.
	/// - Parameters:
	///   - conference: conference object
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(getStatus:resolver:rejecter:)
	public func getStatus(
		conference: [String: Any],
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		guard let conferenceId = conference.identifier,
			  let conference = current,
			  conference.id == conferenceId else {
			ModuleError.noConferenceId.send(with: reject)
			return
		}
			resolve(conference.status.toReactModelValue())
	}
	
	/// Informs whether a participant is muted.
	/// - Parameters:
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(isMuted:rejecter:)
	public func isMuted(
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		resolve(NSNumber(value: VoxeetSDK.shared.conference.isMuted()))
	}
	
	/// Gets the participant's current speaking status.
	/// - Parameters:
	///   - participant: participant object
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(isSpeaking:resolver:rejecter:)
	public func isSpeaking(
		participant: [String: Any],
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		guard let participantObject = current?.findParticipant(with: participant.identifier) else {
			ModuleError.noParticipant(participant.description).send(with: reject)
			return
		}
		resolve(NSNumber(value: VoxeetSDK.shared.conference.isSpeaking(participant: participantObject)))
	}
	
	/// Provides standard WebRTC statistics for the application.
	/// - Parameters:
	///   - resolve: returns local stats on success
	///   - reject: returns error on failure
	@objc(getLocalStats:rejecter:)
	public func getLocalStats(
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		guard let localStats = VoxeetSDK.shared.conference.localStats() else {
			ModuleError.noLocalStats.send(with: reject)
			return
		}
		resolve(localStats)
	}
	
	// MARK: - Setters
	
	/// Enables and disables audio processing for the conference participant..
	/// - Parameters:
	///   - processingOptions: participant object
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(setAudioProcessing:resolver:rejecter:)
	public func setAudioProcessing(
		processingOptions: [String: Any],
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		guard let audioProcessing = processingOptions.audioProcessing else {
			ModuleError.invalidOptions(processingOptions.description).send(with: reject)
			return
		}
		VoxeetSDK.shared.conference.audioProcessing(enable: audioProcessing.boolValue)
		resolve(NSNull())
	}
	
	/// Sets the maximum number of video streams that may be transmitted to the local participant.
	/// - Parameters:
	///   - maxVideoForwarding: The maximum number of video streams that may be transmitted to the local participant.
	///   - participants: The list of the prioritized participants.
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(setMaxVideoForwarding:participants:resolver:rejecter:)
	public func setMaxVideoForwarding(
		maxVideoForwarding: Int,
		participants: [[String:Any]],
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		let videoForwardingOptions = VideoForwardingOptions(strategy: nil,
															max: maxVideoForwarding,
															participants: participants.compactMap { current?.findParticipant(with: $0.identifier) })
		VoxeetSDK.shared.conference.videoForwarding(options: videoForwardingOptions) { error in
			guard let error = error else {
				resolve(NSNull())
				return
			}
			error.send(with: reject)
		}
	}

	/// Sets the maximum number of video streams that may be transmitted to the local participant.
	/// - Parameters:
	///   - strategy: Defines how the SDK should select conference participants whose videos will be transmitted to the local participant. There are two possible values; the selection can be either based on the participants' audio volume or the distance from the local participant.
	///   - max: The maximum number of video streams that may be transmitted to the local participant.
	///   - participants: The list of the prioritized participants.
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(setVideoForwarding:max:participants:resolver:rejecter:)
	public func setVideoForwarding(
		strategy: String?,
		max: NSNumber,
		participants: [[String:Any]]?,
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		let videoForwardingOptions = VideoForwardingOptions(strategy: VideoForwardingStrategy.fromReactModel(value: strategy),
															max: max.intValue,
															participants: participants?.compactMap { current?.findParticipant(with: $0.identifier) })
		VoxeetSDK.shared.conference.videoForwarding(options: videoForwardingOptions) { error in
			guard let error = error else {
				resolve(NSNull())
				return
			}
			error.send(with: reject)
		}
	}
	
	/// Mutes or unmutes output (only compatible with Dolby Voice conferences).
	/// - Parameters:
	///   - isMuted: <code>true</code> if user mutes output. Otherwise, <code>false</code>.
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(muteOutput:resolver:rejecter:)
	public func muteOutput(
		isMuted: Bool,
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		VoxeetSDK.shared.conference.muteOutput(isMuted) { error in
			guard let error = error else {
				resolve(NSNull())
				return
			}
			error.send(with: reject)
		}
	}
	
	/// Mutes or unmutes the specified user.
	/// - Parameters:
	///   - participant: the participant you want to mute.
	///   - resolve: returns on success
	///   - reject: returns error on failure
	// @objc(participant:mute:resolver:rejecter:)
	@objc(mute:isMuted:resolver:rejecter:)
	public func mute(
		participant: [String: Any],
		isMuted: Bool,
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		guard let participantObject = current?.findParticipant(with: participant.identifier) else {
			ModuleError.noParticipant(participant.description).send(with: reject)
			return
		}
		VoxeetSDK.shared.conference.mute(
			participant: participantObject,
			isMuted: isMuted) { error in
				guard let error = error else {
					resolve(NSNull())
					return
				}
				error.send(with: reject)
			}
	}

	/// Starts a screen-sharing session.
	/// - Parameters:
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(startScreenShare:rejecter:)
	public func startScreenShare(
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		// Switching to the main thread, the startScreenShare function calls UIKit functions
		DispatchQueue.main.async {
			VoxeetSDK.shared.conference.startScreenShare(broadcast: true) { error in
				guard let error = error,
							error.code != NativeSdkErrorCodes.broadcastPickerDisplayed.rawValue
				else {
					resolve(NSNull())
					return
				}

				error.send(with: reject)
			}
		}
	}

	/// Stops a screen-sharing session.
	/// - Parameters:
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(stopScreenShare:rejecter:)
	public func stopScreenShare(
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
		// Switching to the main thread, the stopScreenShare function calls UIKit functions
		DispatchQueue.main.async {
			VoxeetSDK.shared.conference.stopScreenShare { error in
				guard let error = error else {
					resolve(NSNull())
					return
				}
				error.send(with: reject)
			}
		}
	}

	/// Sets the direction a participant is facing in space.
	/// - Parameters:
	///   - direction: The direction the local participant is facing in space.
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(setSpatialDirection:resolver:rejecter:)
	public func setSpatialDirection(
		direction: [String: Any],
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
        guard let currentParticipantObject = VoxeetSDK.shared.session.participant else {
            ModuleError.noCurrentParticipant.send(with: reject)
            return
        }
        VoxeetSDK.shared.conference.setSpatialDirection(participant: currentParticipantObject,
                                                        direction: VTSpatialDirection.create(with: direction)) { error in
            guard let error = error else {
                resolve(NSNull())
                return
            }
            error.send(with: reject)
        }
	}

	/// Configures a spatial environment of an application, so the audio renderer understands which directions the application considers forward, up, and right and which units it uses for distance.
	/// - Parameters:
	///   - scale: The application's distance units or scale in application units per one meter. The value must be greater than 0.
	///   - forward: A vector describing the direction the application considers as forward. The value must be orthogonal to up and right.
	///   - up: A vector describing the direction the application considers as up. The value must be orthogonal to forward and right.
	///   - right: A vector describing the direction the application considers as right. The value must be orthogonal to forward and up.
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(setSpatialEnvironment:forward:up:right:resolver:rejecter:)
	public func setSpatialEnvironment(
		scale: [String: Any],
		forward: [String: Any],
		up: [String: Any],
		right: [String: Any],
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
        VoxeetSDK.shared.conference.setSpatialEnvironment(scale: VTSpatialScale.create(with: scale),
                                                          forward: VTSpatialPosition.create(with: forward),
                                                          up: VTSpatialPosition.create(with: up),
                                                          right: VTSpatialPosition.create(with: right)) { error in
            guard let error = error else {
                resolve(NSNull())
                return
            }
            error.send(with: reject)
        }
	}

	/// Sets a participant's position in space to enable the spatial audio experience during a Dolby Voice conference.
	/// - Parameters:
	///   - participant: The selected remote participant.
	///   - position: The participant's audio location from which their audio will be rendered.
	///   - resolve: returns on success
	///   - reject: returns error on failure
	@objc(setSpatialPosition:position:resolver:rejecter:)
	public func setSpatialPosition(
		participant: [String: Any],
		position: [String: Any],
		resolve: @escaping RCTPromiseResolveBlock,
		reject: @escaping RCTPromiseRejectBlock
	) {
        guard let participantObject = current?.findParticipant(with: participant.identifier) else {
            ModuleError.noParticipant(participant.description).send(with: reject)
            return
        }
        VoxeetSDK.shared.conference.setSpatialPosition(participant: participantObject,
                                                       position: VTSpatialPosition.create(with: position)) { error in
            guard let error = error else {
                resolve(NSNull())
                return
            }
            error.send(with: reject)
		}
	}
}

extension ConferenceServiceModule: VTConferenceDelegate {
	public func statusUpdated(status: VTConferenceStatus) {
		send(
			event: EventKeys.statusUpdated,
			body: StatusDTO(
				status: status
			).toReactModel()
		)
	}

	public func permissionsUpdated(permissions: [Int]) {
		send(
			event: EventKeys.permissionsUpdated,
			body: PermissionsDTO(
				permissions: permissions.compactMap { VTConferencePermission(rawValue: $0) }
			).toReactModel()
		)
	}

	public func participantAdded(participant: VTParticipant) {
		send(
			event: EventKeys.participantAdded,
			body: ParticipantDTO(
				participant: participant
			).toReactModel()
		)
	}

	public func participantUpdated(participant: VTParticipant) {
		send(
			event: EventKeys.participantUpdated,
			body: ParticipantDTO(
				participant: participant
			).toReactModel()
		)
	}

	public func streamAdded(participant: VTParticipant, stream: MediaStream) {
		send(
			event: EventKeys.streamAdded,
			body: StreamDTO(
				participant: participant,
				stream: stream
			).toReactModel()
		)
	}

	public func streamUpdated(participant: VTParticipant, stream: MediaStream) {
		send(
			event: EventKeys.streamUpdated,
			body: StreamDTO(
				participant: participant,
				stream: stream
			).toReactModel()
		)
	}

	public func streamRemoved(participant: VTParticipant, stream: MediaStream) {
		send(
			event: EventKeys.streamRemoved,
			body: StreamDTO(
				participant: participant,
				stream: stream
			).toReactModel()
		)
	}
}
