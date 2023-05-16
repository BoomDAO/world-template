using offerId = System.String;
using TokenIndex = System.UInt32;
using AccountIdentifier = System.String;
using EdjCase.ICP.Candid.Mapping;
using Candid.game.Models;
using System;

namespace Candid.game.Models
{
	[Variant(typeof(Result_1Tag))]
	public class Result_1
	{
		[VariantTagProperty()]
		public Result_1Tag Tag { get; set; }

		[VariantValueProperty()]
		public System.Object? Value { get; set; }

		public Result_1(Result_1Tag tag, object? value)
		{
			this.Tag = tag;
			this.Value = value;
		}

		protected Result_1()
		{
		}

		public static Result_1 Err(string info)
		{
			return new Result_1(Result_1Tag.Err, info);
		}

		public static Result_1 Ok(CoreTxData info)
		{
			return new Result_1(Result_1Tag.Ok, info);
		}

		public string AsErr()
		{
			this.ValidateTag(Result_1Tag.Err);
			return (string)this.Value!;
		}

		public CoreTxData AsOk()
		{
			this.ValidateTag(Result_1Tag.Ok);
			return (CoreTxData)this.Value!;
		}

		private void ValidateTag(Result_1Tag tag)
		{
			if (!this.Tag.Equals(tag))
			{
				throw new InvalidOperationException($"Cannot cast '{this.Tag}' to type '{tag}'");
			}
		}
	}

	public enum Result_1Tag
	{
		[CandidName("err")]
		[VariantOptionType(typeof(string))]
		Err,
		[CandidName("ok")]
		[VariantOptionType(typeof(CoreTxData))]
		Ok
	}
}