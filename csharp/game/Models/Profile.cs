using offerId = System.String;
using TokenIndex = System.UInt32;
using AccountIdentifier = System.String;
using EdjCase.ICP.Candid.Mapping;

namespace Candid.game.Models
{
	public class Profile
	{
		[CandidName("avatarKey")]
		public string AvatarKey { get; set; }

		[CandidName("name")]
		public string Name { get; set; }

		[CandidName("url")]
		public string Url { get; set; }

		public Profile(string avatarKey, string name, string url)
		{
			this.AvatarKey = avatarKey;
			this.Name = name;
			this.Url = url;
		}

		public Profile()
		{
		}
	}
}